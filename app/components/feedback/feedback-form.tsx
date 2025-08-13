'use client'

import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Send, User, MessageSquare, CheckCircle, AlertCircle } from 'lucide-react'
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
  const [touched, setTouched] = useState<{ name: boolean; message: boolean }>({
    name: false,
    message: false
  })
  const [showNameError, setShowNameError] = useState(false)
  const [showMessageError, setShowMessageError] = useState(false)
  const [isHovered, setIsHovered] = useState(false)

  // Auto-dismiss error messages after 3 seconds
  useEffect(() => {
    if (showNameError) {
      const timer = setTimeout(() => {
        setShowNameError(false)
      }, 3000)
      return () => clearTimeout(timer)
    }
  }, [showNameError])

  useEffect(() => {
    if (showMessageError) {
      const timer = setTimeout(() => {
        setShowMessageError(false)
      }, 3000)
      return () => clearTimeout(timer)
    }
  }, [showMessageError])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData.name.trim() || !formData.message.trim()) {
      return
    }
    
    await onSubmit(formData)
    setFormData({ name: '', message: '' })
    setTouched({ name: false, message: false })
    setShowNameError(false)
    setShowMessageError(false)
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
    
    // Hide error message when user starts typing
    if (name === 'name' && showNameError) {
      setShowNameError(false)
    }
    if (name === 'message' && showMessageError) {
      setShowMessageError(false)
    }
  }

  const handleBlur = (field: 'name' | 'message') => {
    setTouched(prev => ({ ...prev, [field]: true }))
    
    // Show error message when field loses focus and is empty
    if (field === 'name' && !formData.name.trim()) {
      setShowNameError(true)
    }
    if (field === 'message' && !formData.message.trim()) {
      setShowMessageError(true)
    }
  }

  const isFormValid = formData.name.trim() && formData.message.trim()
  const nameError = touched.name && !formData.name.trim()
  const messageError = touched.message && !formData.message.trim()

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      className="space-y-6"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Name Field */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.1, duration: 0.6 }}
          className="space-y-3"
        >
          <motion.div 
            className="flex items-center space-x-2 text-sm font-medium text-foreground"
            animate={{
              textShadow: isHovered 
                ? ["0 0 5px rgba(59, 130, 246, 0.3)", "0 0 15px rgba(59, 130, 246, 0.6)", "0 0 5px rgba(59, 130, 246, 0.3)"]
                : ["0 0 0px rgba(59, 130, 246, 0)", "0 0 0px rgba(59, 130, 246, 0)", "0 0 0px rgba(59, 130, 246, 0)"]
            }}
            transition={{ duration: 1.5, repeat: Infinity }}
          >
            <motion.div
              animate={{ 
                rotate: isHovered ? [0, 10, -10, 0] : 0,
                scale: isHovered ? [1, 1.1, 1] : 1
              }}
              transition={{ duration: 1, repeat: Infinity }}
            >
              <User className="h-4 w-4 text-primary" />
            </motion.div>
            <label htmlFor="name" className="cursor-pointer">Name *</label>
          </motion.div>
          <div className="relative">
            <motion.input
              type="text"
              id="name"
              name="name"
              value={formData.name}
              onChange={handleChange}
              onBlur={() => handleBlur('name')}
              required
              className={`w-full px-4 py-3 bg-background border rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-ring focus:border-ring text-foreground placeholder:text-muted-foreground transition-all duration-300 ${
                nameError && showNameError
                  ? 'border-destructive focus:ring-destructive' 
                  : formData.name.trim() 
                    ? 'border-green-500 focus:ring-green-500' 
                    : 'border-input focus:ring-primary'
              }`}
              placeholder="Enter your name"
              disabled={isLoading}
              whileFocus={{ 
                scale: 1.02,
                boxShadow: "0 0 20px rgba(59, 130, 246, 0.3)"
              }}
              animate={{
                borderColor: isHovered 
                  ? ["hsl(var(--border))", "hsl(var(--primary))", "hsl(var(--border))"]
                  : ["hsl(var(--border))", "hsl(var(--border))", "hsl(var(--border))"]
              }}
              transition={{ duration: 2, repeat: Infinity }}
            />
            <AnimatePresence>
              {formData.name.trim() && !nameError && (
                <motion.div
                  className="absolute right-3 top-1/2 transform -translate-y-1/2"
                  initial={{ opacity: 0, scale: 0.8, rotate: -180 }}
                  animate={{ opacity: 1, scale: 1, rotate: 0 }}
                  exit={{ opacity: 0, scale: 0.8, rotate: 180 }}
                  whileHover={{ scale: 1.2, rotate: 360 }}
                  transition={{ type: "spring", stiffness: 200 }}
                >
                  <CheckCircle className="h-5 w-5 text-green-500" />
                </motion.div>
              )}
              {nameError && showNameError && (
                <motion.div
                  className="absolute right-3 top-1/2 transform -translate-y-1/2"
                  initial={{ opacity: 0, scale: 0.8, x: -20 }}
                  animate={{ opacity: 1, scale: 1, x: 0 }}
                  exit={{ opacity: 0, scale: 0.8, x: 20 }}
                  whileHover={{ scale: 1.2, rotate: [0, -10, 10, 0] }}
                  transition={{ type: "spring", stiffness: 200 }}
                >
                  <AlertCircle className="h-5 w-5 text-destructive" />
                </motion.div>
              )}
            </AnimatePresence>
          </div>
          <AnimatePresence>
            {nameError && showNameError && (
              <motion.div
                initial={{ opacity: 0, y: -10, x: -20 }}
                animate={{ opacity: 1, y: 0, x: 0 }}
                exit={{ opacity: 0, y: -10, x: 20 }}
                className="text-sm text-destructive flex items-center space-x-1"
              >
                <motion.div
                  animate={{ rotate: [0, 10, -10, 0] }}
                  transition={{ duration: 0.5, repeat: Infinity }}
                >
                  <AlertCircle className="h-4 w-4" />
                </motion.div>
                <span>Name is required</span>
              </motion.div>
            )}
          </AnimatePresence>
        </motion.div>
        
        {/* Message Field */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.2, duration: 0.6 }}
          className="space-y-3"
        >
          <motion.div 
            className="flex items-center space-x-2 text-sm font-medium text-foreground"
            animate={{
              textShadow: isHovered 
                ? ["0 0 5px rgba(59, 130, 246, 0.3)", "0 0 15px rgba(59, 130, 246, 0.6)", "0 0 5px rgba(59, 130, 246, 0.3)"]
                : ["0 0 0px rgba(59, 130, 246, 0)", "0 0 0px rgba(59, 130, 246, 0)", "0 0 0px rgba(59, 130, 246, 0)"]
            }}
            transition={{ duration: 1.5, repeat: Infinity, delay: 0.2 }}
          >
            <motion.div
              animate={{ 
                rotate: isHovered ? [0, -10, 10, 0] : 0,
                scale: isHovered ? [1, 1.1, 1] : 1
              }}
              transition={{ duration: 1, repeat: Infinity, delay: 0.1 }}
            >
              <MessageSquare className="h-4 w-4 text-primary" />
            </motion.div>
            <label htmlFor="message" className="cursor-pointer">Message *</label>
          </motion.div>
          <div className="relative">
            <motion.textarea
              id="message"
              name="message"
              value={formData.message}
              onChange={handleChange}
              onBlur={() => handleBlur('message')}
              required
              rows={4}
              className={`w-full px-4 py-3 bg-background border rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-ring focus:border-ring text-foreground placeholder:text-muted-foreground transition-all duration-300 resize-none ${
                messageError && showMessageError
                  ? 'border-destructive focus:ring-destructive' 
                  : formData.message.trim() 
                    ? 'border-green-500 focus:ring-green-500' 
                    : 'border-input focus:ring-primary'
              }`}
              placeholder="Share your feedback, suggestions, or thoughts..."
              disabled={isLoading}
              whileFocus={{ 
                scale: 1.02,
                boxShadow: "0 0 20px rgba(59, 130, 246, 0.3)"
              }}
              animate={{
                borderColor: isHovered 
                  ? ["hsl(var(--border))", "hsl(var(--primary))", "hsl(var(--border))"]
                  : ["hsl(var(--border))", "hsl(var(--border))", "hsl(var(--border))"]
              }}
              transition={{ duration: 2, repeat: Infinity, delay: 0.1 }}
            />
            <AnimatePresence>
              {formData.message.trim() && !messageError && (
                <motion.div
                  className="absolute right-3 top-3"
                  initial={{ opacity: 0, scale: 0.8, rotate: -180 }}
                  animate={{ opacity: 1, scale: 1, rotate: 0 }}
                  exit={{ opacity: 0, scale: 0.8, rotate: 180 }}
                  whileHover={{ scale: 1.2, rotate: 360 }}
                  transition={{ type: "spring", stiffness: 200 }}
                >
                  <CheckCircle className="h-5 w-5 text-green-500" />
                </motion.div>
              )}
              {messageError && showMessageError && (
                <motion.div
                  className="absolute right-3 top-3"
                  initial={{ opacity: 0, scale: 0.8, x: -20 }}
                  animate={{ opacity: 1, scale: 1, x: 0 }}
                  exit={{ opacity: 0, scale: 0.8, x: 20 }}
                  whileHover={{ scale: 1.2, rotate: [0, -10, 10, 0] }}
                  transition={{ type: "spring", stiffness: 200 }}
                >
                  <AlertCircle className="h-5 w-5 text-destructive" />
                </motion.div>
              )}
            </AnimatePresence>
          </div>
          <AnimatePresence>
            {messageError && showMessageError && (
              <motion.div
                initial={{ opacity: 0, y: -10, x: -20 }}
                animate={{ opacity: 1, y: 0, x: 0 }}
                exit={{ opacity: 0, y: -10, x: 20 }}
                className="text-sm text-destructive flex items-center space-x-1"
              >
                <motion.div
                  animate={{ rotate: [0, -10, 10, 0] }}
                  transition={{ duration: 0.5, repeat: Infinity }}
                >
                  <AlertCircle className="h-4 w-4" />
                </motion.div>
                <span>Message is required</span>
              </motion.div>
            )}
          </AnimatePresence>
        </motion.div>
        
        {/* Submit Button */}
        <motion.button
          type="submit"
          disabled={isLoading || !isFormValid}
          className="w-full bg-primary text-primary-foreground py-4 px-6 rounded-lg hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-300 flex items-center justify-center space-x-3 shadow-lg hover:shadow-xl relative overflow-hidden"
          whileHover={{ 
            scale: isFormValid ? 1.02 : 1, 
            y: -2,
            boxShadow: "0 20px 40px rgba(59, 130, 246, 0.3)"
          }}
          whileTap={{ 
            scale: isFormValid ? 0.98 : 1,
            rotate: isFormValid ? 2 : 0
          }}
          onMouseEnter={() => setIsHovered(true)}
          onMouseLeave={() => setIsHovered(false)}
        >
          {/* Animated background */}
          <motion.div
            className="absolute inset-0 bg-gradient-to-r from-primary via-primary/80 to-primary"
            animate={{
              background: [
                "linear-gradient(45deg, hsl(var(--primary)), hsl(var(--primary)/80), hsl(var(--primary)))",
                "linear-gradient(45deg, hsl(var(--primary)/80), hsl(var(--primary)), hsl(var(--primary)/80))",
                "linear-gradient(45deg, hsl(var(--primary)), hsl(var(--primary)/80), hsl(var(--primary)))"
              ]
            }}
            transition={{ duration: 2, repeat: Infinity }}
          />
          
          {/* Floating particles on hover */}
          {isHovered && (
            <>
              {[...Array(3)].map((_, i) => (
                <motion.div
                  key={i}
                  className="absolute w-1 h-1 bg-white/60 rounded-full pointer-events-none"
                  style={{
                    left: `${30 + i * 20}%`,
                    top: `${40 + i * 10}%`
                  }}
                  initial={{ opacity: 0, scale: 0, y: 0 }}
                  animate={{ 
                    opacity: [0, 1, 0], 
                    scale: [0, 1.5, 0],
                    y: [-10, -20, -10],
                    x: [0, Math.random() * 10 - 5, 0]
                  }}
                  transition={{ 
                    duration: 1.5, 
                    repeat: Infinity, 
                    delay: i * 0.2,
                    ease: "easeInOut"
                  }}
                />
              ))}
            </>
          )}
          
          {isLoading ? (
            <>
              <LoadingSpinner size="sm" className="border-primary-foreground border-t-primary-foreground relative z-10" />
              <span className="relative z-10">Submitting...</span>
            </>
          ) : (
            <>
              <motion.div
                className="relative z-10"
                animate={{ 
                  x: [0, 3, 0],
                  rotate: isHovered ? [0, 5, -5, 0] : [0, 3, 0]
                }}
                transition={{ 
                  duration: 1.5, 
                  repeat: Infinity, 
                  ease: "easeInOut"
                }}
              >
                <Send className="h-5 w-5" />
              </motion.div>
              <span className="relative z-10">Submit Feedback</span>
            </>
          )}
        </motion.button>
      </form>

      {/* Form Tips */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4, duration: 0.6 }}
        className="text-xs text-muted-foreground text-center p-4 bg-black/50 rounded-lg border border-border/50 relative overflow-hidden"
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        {/* Morphing background */}
        <motion.div
          className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-primary/10"
          animate={{
            borderRadius: isHovered 
              ? ["50%", "30% 70% 70% 30% / 30% 30% 70% 70%"]
              : ["30% 70% 70% 30% / 30% 30% 70% 70%", "50%"]
          }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
        />
        
        <motion.div 
          className="flex items-center justify-center space-x-2 relative z-10"
          animate={{
            textShadow: isHovered 
              ? ["0 0 5px rgba(59, 130, 246, 0.3)", "0 0 15px rgba(59, 130, 246, 0.6)", "0 0 5px rgba(59, 130, 246, 0.3)"]
              : ["0 0 0px rgba(59, 130, 246, 0)", "0 0 0px rgba(59, 130, 246, 0)", "0 0 0px rgba(59, 130, 246, 0)"]
          }}
          transition={{ duration: 1.5, repeat: Infinity }}
        >
          <motion.div
            animate={{ 
              rotate: isHovered ? [0, 360] : 0,
              scale: isHovered ? [1, 1.2, 1] : 1
            }}
            transition={{ duration: 2, repeat: Infinity }}
          >
            <CheckCircle className="h-4 w-4 text-primary" />
          </motion.div>
          <span>Your feedback helps us improve. We appreciate your input!</span>
        </motion.div>
      </motion.div>
    </motion.div>
  )
} 