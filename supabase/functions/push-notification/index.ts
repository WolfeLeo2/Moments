import { createClient } from 'jsr:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

interface FirebaseServiceAccount {
  project_id: string
  client_email: string
  private_key: string
}

interface NotificationRecord {
  user_id: string
  actor_id?: string
  title: string
  body: string
  type: string
  related_id?: string
  image_url?: string // For rich notifications
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: NotificationRecord
  schema: string
  old_record: null | NotificationRecord
}

interface FCMError {
  error?: {
    code?: number
    message?: string
    status?: string
    details?: Array<{
      '@type': string
      errorCode?: string
    }>
  }
}

function loadServiceAccount(): FirebaseServiceAccount | null {
  const raw =
    Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ??
    Deno.env.get('GOOGLE_SERVICE_ACCOUNT_JSON')

  if (!raw) {
    console.error('Missing FIREBASE_SERVICE_ACCOUNT_JSON secret')
    return null
  }

  try {
    const parsed = JSON.parse(raw) as FirebaseServiceAccount

    if (!parsed.client_email || !parsed.private_key || !parsed.project_id) {
      console.error('FIREBASE_SERVICE_ACCOUNT_JSON is missing required fields')
      return null
    }

    return {
      project_id: parsed.project_id,
      client_email: parsed.client_email,
      // Secrets managers often store newlines as escaped \n.
      private_key: parsed.private_key.replace(/\\n/g, '\n'),
    }
  } catch (error) {
    console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON', error)
    return null
  }
}

Deno.serve(async (req) => {
  const serviceAccount = loadServiceAccount()
  if (!serviceAccount) {
    return new Response('Firebase service account is not configured', {
      status: 500,
    })
  }

  const payload: WebhookPayload = await req.json()
  const { record } = payload

  console.log('Received webhook payload:', payload)

  if (!record) {
    return new Response('No record found', { status: 400 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  // 1. Check user's notification preferences
  const { data: preferences } = await supabase
    .from('notification_preferences')
    .select('*')
    .eq('user_id', record.user_id)
    .maybeSingle()

  // If user has disabled this notification type, skip
  if (preferences) {
    const typeKey = `${record.type}_enabled` as keyof typeof preferences
    if (preferences[typeKey] === false) {
      console.log(`User has disabled ${record.type} notifications`)
      return new Response('Notification type disabled by user', { status: 200 })
    }
    // Check master switch
    if (preferences.push_enabled === false) {
      console.log('User has disabled all push notifications')
      return new Response('Push notifications disabled by user', { status: 200 })
    }
  }

  // 2. Get the user's FCM tokens
  const { data: devices, error } = await supabase
    .from('user_devices')
    .select('id, fcm_token')
    .eq('user_id', record.user_id)

  if (error) {
    console.error('Error fetching devices:', error)
    return new Response('Error fetching devices', { status: 500 })
  }

  if (!devices || devices.length === 0) {
    console.log('No devices found for user:', record.user_id)
    return new Response('No devices found', { status: 200 })
  }

  // 3. Fetch actor's avatar for rich notifications (Sender Avatar)
  let senderAvatarUrl = ''
  let senderName = ''

  if (record.actor_id) {
    const { data: actorProfile } = await supabase
      .from('profiles')
      .select('avatar_url, display_name, username')
      .eq('id', record.actor_id)
      .maybeSingle()

    if (actorProfile) {
      if (actorProfile.avatar_url) senderAvatarUrl = actorProfile.avatar_url
      senderName = actorProfile.display_name || actorProfile.username || ''
    }
  }

  // Fallback: If no actor (e.g. system message), use the record's image_url if available
  if (!senderAvatarUrl && record.image_url) {
    senderAvatarUrl = record.image_url
  }

  // 4. Get Access Token for FCM
  const jwtClient = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  })

  try {
    const tokens = await jwtClient.authorize()
    const accessToken = tokens.access_token

    // 5. Send Notifications & Track invalid tokens
    const invalidTokenIds: string[] = []

    const promises = devices.map(async (device: { id: string; fcm_token: string }) => {
      // Build FCM message with DATA-ONLY payload for Android
      // Flutter handles notification display with MessagingStyle + Dynamic Shortcut
      // iOS uses APNS notification block for native rendering
      const message = {
        message: {
          token: device.fcm_token,
          // NO notification block - Flutter handles display on Android
          android: {
            priority: 'high' as const,
            // No notification sub-block - data-only for MessagingStyle
          },
          apns: {
            payload: {
              aps: {
                alert: {
                  title: senderName || record.title,
                  body: record.body,
                },
                sound: 'default',
                badge: 1,
                'mutable-content': 1,
                'thread-id': record.related_id || record.type, // iOS threading
              },
            },
            fcm_options: {
              ...(senderAvatarUrl && { image: senderAvatarUrl }),
            },
          },
          data: {
            type: record.type,
            title: record.title,
            body: record.body,
            related_id: record.related_id ?? '',
            actor_id: record.actor_id ?? '',
            actor_name: senderName,
            avatar_url: senderAvatarUrl,
            // For moment_like, use the moment's image instead of avatar
            image_url: record.type === 'moment_like' && record.image_url ? record.image_url : senderAvatarUrl,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      }

      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify(message),
        }
      )

      const result: FCMError = await res.json()
      console.log('FCM Result for device', device.id, ':', result)

      // TOKEN CLEANUP: Check for invalid token errors
      if (result.error) {
        const errorCode = result.error.details?.[0]?.errorCode || result.error.status
        if (errorCode === 'UNREGISTERED' || errorCode === 'INVALID_ARGUMENT' ||
          result.error.message?.includes('not a valid FCM registration token')) {
          console.log('Invalid token detected, marking for deletion:', device.id)
          invalidTokenIds.push(device.id)
        }
      }

      return result
    })

    await Promise.all(promises)

    // 6. TOKEN CLEANUP: Delete invalid tokens from database
    if (invalidTokenIds.length > 0) {
      console.log('Cleaning up invalid tokens:', invalidTokenIds)
      const { error: deleteError } = await supabase
        .from('user_devices')
        .delete()
        .in('id', invalidTokenIds)

      if (deleteError) {
        console.error('Error deleting invalid tokens:', deleteError)
      } else {
        console.log(`Successfully deleted ${invalidTokenIds.length} invalid tokens`)
      }
    }

    return new Response('Notifications sent', { status: 200 })

  } catch (e) {
    console.error('Error sending notifications:', e)
    return new Response('Error sending notifications', { status: 500 })
  }
})
