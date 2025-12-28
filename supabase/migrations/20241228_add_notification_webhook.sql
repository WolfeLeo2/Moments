-- Enable pg_net extension for HTTP requests
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Create the function to call the Edge Function
CREATE OR REPLACE FUNCTION public.handle_new_message_notification()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://voxutceosbctxfmlqjfk.supabase.co/functions/v1/push-notification',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZveHV0Y2Vvc2JjdHhmbWxxamZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI0NTEzNjcsImV4cCI6MjA3ODAyNzM2N30.s2oXwNXV6UcJ4tMHWjZFxxG6JvsA32gqrToGoFhTwC0"}'::jsonb,
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'schema', TG_TABLE_SCHEMA,
      'record', row_to_json(NEW),
      'old_record', null
    )
  );
  return new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, net, extensions;

-- Create the trigger
DROP TRIGGER IF EXISTS on_new_message_notification ON public.messages;
CREATE TRIGGER on_new_message_notification
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_message_notification();
