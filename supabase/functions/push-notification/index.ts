import { createClient } from 'jsr:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from './service-account.json' with { type: 'json' }

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

Deno.serve(async (req) => {
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
  // We prioritize the actor's avatar to ensure the "Sender Avatar" style for ALL notification types
  // (Friend Requests, Invites, New Moments, etc.)
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
      // Prioritize display_name, fallback to username
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

    const promises = devices.map(async (device) => {
      // Build the FCM message
      // We use DATA-ONLY messages to allow the Flutter app to handle the display
      // This enables "MessagingStyle" notifications (Person avatar as icon) which isn't possible
      // with standard notification payloads on Android.
      const message: Record<string, unknown> = {
        message: {
          token: device.fcm_token,
          // notification: { ... }  <-- REMOVED to prevent auto-display
          android: {
            priority: 'high', // Essential for data-only messages to wake the app
          },
          apns: {
            payload: {
              aps: {
                'content-available': 1, // Essential for background execution on iOS
                alert: { // Optional: Include alert for iOS fallback if data processing fails
                   title: record.title,
                   body: record.body,
                },
                sound: 'default',
                'mutable-content': 1,
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
        // UNREGISTERED = app uninstalled, INVALID_ARGUMENT = malformed token
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
