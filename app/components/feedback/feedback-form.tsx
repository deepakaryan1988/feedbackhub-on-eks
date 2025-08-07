'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Send, User, MessageSquare } from 'lucide-react'
import { FeedbackFormData } from '../../types/feedback'
import LoadingSpinner from '../LoadingSpinner'

interface FeedbackFormProps {
  onSubmit: (data: FeedbackFormData) => Promise<void>
  isLoading?: boolean
}

export default function FeedbackForm({ onSubmit, isLoading = false }: FeedbackFormProps) {
  const [formData, setFormData] = useState<FeedbackFormData>({
    name: '',
    message: ''
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData.name.trim() || !formData.message.trim()) {
      return
    }
    
    await onSubmit(formData)
    setFormData({ name: '', message: '' })
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
  }

  const isFormValid = formData.name.trim() && formData.message.trim()

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="space-y-6"
    >


      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Name Field */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.1 }}
          className="space-y-2"
        >
          <label htmlFor="name" className="flex items-center space-x-2 text-sm font-medium text-foreground">
            <User className="h-4 w-4" />
            <span>Name *</span>
          </label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleChange}
            required
            className="w-full px-4 py-3 bg-background border border-input rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-ring focus:border-ring text-foreground placeholder:text-muted-foreground transition-all"
            placeholder="Enter your name"
            disabled={isLoading}
          />
        </motion.div>
        
        {/* Message Field */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.2 }}
          className="space-y-2"
        >
          <label htmlFor="message" className="flex items-center space-x-2 text-sm font-medium text-foreground">
            <MessageSquare className="h-4 w-4" />
            <span>Message *</span>
          </label>
          <textarea
            id="message"
            name="message"
            value={formData.message}
            onChange={handleChange}
            required
            rows={4}
            className="w-full px-4 py-3 bg-background border border-input rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-ring focus:border-ring text-foreground placeholder:text-muted-foreground transition-all resize-none"
            placeholder="Share your feedback, suggestions, or thoughts..."
            disabled={isLoading}
          />
        </motion.div>
        
        {/* Submit Button */}
        <motion.button
          type="submit"
          disabled={isLoading || !isFormValid}
          className="w-full bg-primary text-primary-foreground py-3 px-6 rounded-lg hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 flex items-center justify-center space-x-2 shadow-lg"
          whileHover={{ scale: isFormValid ? 1.02 : 1 }}
          whileTap={{ scale: isFormValid ? 0.98 : 1 }}
        >
          {isLoading ? (
            <>
              <LoadingSpinner size="sm" className="border-primary-foreground border-t-primary-foreground" />
              <span>Submitting...</span>
            </>
          ) : (
            <>
              <Send className="h-4 w-4" />
              <span>Submit Feedback</span>
            </>
          )}
        </motion.button>
      </form>

      {/* Form Tips */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="text-xs text-muted-foreground text-center"
      >
        <p>Your feedback helps us improve. We appreciate your input!</p>
      </motion.div>
    </motion.div>
  )
} 