'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import HeroSection from './components/layout/hero-section'
import FeedbackForm from './components/feedback/feedback-form'
import FeedbackList from './components/feedback/feedback-list'
import { Feedback, FeedbackFormData } from './types/feedback'
import { useToast } from './hooks/use-toast'

export default function HomePage() {
  const [feedbacks, setFeedbacks] = useState<Feedback[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const { toast } = useToast()

  useEffect(() => {
    fetchFeedbacks()
  }, [])

  const fetchFeedbacks = async () => {
    setIsLoading(true)
    try {
      const response = await fetch('/api/feedback')
      const data = await response.json()
      if (data.success) {
        setFeedbacks(data.data || [])
      } else {
        toast({
          title: "Error",
          description: "Failed to load feedbacks",
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error('Error fetching feedbacks:', error)
      toast({
        title: "Error",
        description: "Failed to load feedbacks",
        variant: "destructive",
      })
    } finally {
      setIsLoading(false)
    }
  }

  const handleSubmitFeedback = async (formData: FeedbackFormData) => {
    setIsSubmitting(true)
    try {
      const response = await fetch('/api/feedback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      })

      const data = await response.json()
      if (data.success) {
        // Add the new feedback to the list immediately with animation
        const newFeedback: Feedback = {
          _id: data.data._id,
          name: formData.name,
          message: formData.message,
          createdAt: new Date()
        }
        setFeedbacks(prev => [newFeedback, ...prev])
        toast({
          title: "Success",
          description: "Feedback submitted successfully!",
        })
      } else {
        toast({
          title: "Error",
          description: data.error || "Failed to submit feedback",
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error('Error submitting feedback:', error)
      toast({
        title: "Error",
        description: "Failed to submit feedback",
        variant: "destructive",
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <HeroSection />

      {/* Main Content */}
      <section className="py-16 bg-muted/30">
        <div className="container mx-auto px-4">
          <motion.div 
            className="max-w-6xl mx-auto"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.8 }}
          >
            {/* Section Header */}
            <motion.div 
              className="text-center mb-12"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
            >
              <h2 className="text-3xl md:text-4xl font-bold text-foreground mb-4">
                Share Your Feedback
              </h2>
              <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
                Help us improve by sharing your thoughts, suggestions, and experiences. 
                Every piece of feedback matters.
              </p>
            </motion.div>

            {/* Content Grid */}
            <motion.div 
              className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
            >
              {/* Feedback Form Section */}
              <motion.div 
                className="bg-card border border-border rounded-lg p-8 shadow-sm"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.6 }}
                id="feedback-form"
              >
                <h3 className="text-2xl font-semibold text-foreground mb-6">
                  Submit Feedback
                </h3>
                <FeedbackForm onSubmit={handleSubmitFeedback} isLoading={isSubmitting} />
              </motion.div>

              {/* Feedback List Section */}
              <motion.div 
                className="bg-card border border-border rounded-lg p-8 shadow-sm"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.8 }}
              >
                <h3 className="text-2xl font-semibold text-foreground mb-6">
                  Recent Feedback
                </h3>
                <FeedbackList feedbacks={feedbacks} isLoading={isLoading} />
              </motion.div>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border bg-muted/30">
        <div className="container mx-auto px-4 py-12">
          <motion.div 
            className="text-center"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.0 }}
          >
            <div className="flex items-center justify-center space-x-2 mb-4">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
                <svg className="h-4 w-4 text-primary-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </div>
              <span className="text-xl font-bold text-foreground">FeedbackHub</span>
            </div>
            <p className="text-muted-foreground mb-2">
              A modern feedback platform built with Next.js and shadcn/ui
            </p>
            <p className="text-sm text-muted-foreground">
              © 2024 FeedbackHub. All rights reserved.
            </p>
          </motion.div>
        </div>
      </footer>
      
    </div>
  )
} 