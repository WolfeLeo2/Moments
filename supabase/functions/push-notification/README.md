# Push Notification Edge Function

This function listens for database webhooks (e.g., on the `notifications` table) and sends FCM push notifications to the user's devices.

## Setup

1.  **Service Account Secret**:

    - Go to Firebase Console -> Project Settings -> Service accounts.
    - Generate a new private key.
    - Store the full JSON as a Supabase function secret (do not commit any file):

    ```bash
    supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
    ```

    _Tip:_ pass the JSON as one line or with properly escaped newlines in `private_key`.

2.  **Deploy**:

    ```bash
    supabase functions deploy push-notification --no-verify-jwt
    ```

    _Note: `--no-verify-jwt` is used because the webhook from Supabase Database doesn't sign the request with the user's JWT._

3.  **Database Webhook**:
    - Go to Supabase Dashboard -> Database -> Webhooks.
    - Create a new webhook.
    - Name: `push-notification`.
    - Table: `notifications`.
    - Events: `INSERT`.
    - Type: `HTTP Request`.
    - URL: `https://<your-project-ref>.supabase.co/functions/v1/push-notification`.
    - Method: `POST`.
    - Headers: `Content-Type: application/json`, `Authorization: Bearer <your-anon-key>`.

## Environment Variables

Ensure you have the following Supabase project secrets configured:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `FIREBASE_SERVICE_ACCOUNT_JSON`
