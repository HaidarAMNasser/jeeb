export interface NotificationStrategy {
  sendOtp(to: string, otp: string): Promise<void>;
  sendWelcomeMessage(to: string, name: string): Promise<void>;
  // Add more methods as needed
}
