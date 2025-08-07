export interface Feedback {
  _id?: string
  name: string
  message: string
  createdAt: Date | string
}

export interface FeedbackFormData {
  name: string
  message: string
}

export interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
} 