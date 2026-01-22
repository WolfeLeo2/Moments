-- Add DELETE policy for notifications
-- Users should be able to delete their own notifications (swipe to dismiss)

DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications" 
ON public.notifications 
FOR DELETE 
USING ((select auth.uid()) = user_id);
