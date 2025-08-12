import { motion, AnimatePresence } from 'framer-motion'
import { Feedback } from '../../types/feedback'
import FeedbackCard from './feedback-card'
import EmptyState from './empty-state'

interface FeedbackListProps {
  feedbacks: Feedback[]
  isLoading?: boolean
}

export default function FeedbackList({ feedbacks, isLoading = false }: FeedbackListProps) {
  if (isLoading) {
    return (
      <motion.div 
        className="space-y-4"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.6 }}
      >
        <motion.div 
          className="text-center mb-6"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          <div className="inline-flex items-center space-x-2 text-sm text-muted-foreground">
            <div className="w-2 h-2 bg-primary rounded-full animate-pulse"></div>
            <span>Loading feedback...</span>
          </div>
        </motion.div>
        
        {[...Array(3)].map((_, i) => (
          <motion.div 
            key={i} 
            className="bg-card border border-border p-6 rounded-xl animate-pulse"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 + i * 0.1, duration: 0.6 }}
          >
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-8 h-8 bg-muted rounded-full"></div>
              <div className="space-y-2">
                <div className="h-4 bg-muted rounded w-24"></div>
                <div className="h-3 bg-muted rounded w-16"></div>
              </div>
            </div>
            <div className="space-y-2">
              <div className="h-4 bg-muted rounded w-full"></div>
              <div className="h-4 bg-muted rounded w-3/4"></div>
              <div className="h-4 bg-muted rounded w-1/2"></div>
            </div>
          </motion.div>
        ))}
      </motion.div>
    )
  }

  if (feedbacks.length === 0) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
      >
        <EmptyState />
      </motion.div>
    )
  }

  return (
    <motion.div 
      className="space-y-4"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.6 }}
    >
      {/* List Header */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2, duration: 0.6 }}
        className="flex items-center justify-between mb-6"
      >
        <h4 className="text-lg font-semibold text-foreground">
          Recent Feedback ({feedbacks.length})
        </h4>
        <div className="flex items-center space-x-2 text-sm text-muted-foreground">
          <div className="w-2 h-2 bg-green-500 rounded-full"></div>
          <span>Live updates</span>
        </div>
      </motion.div>

      {/* Feedback Items */}
      <AnimatePresence mode="popLayout">
        {feedbacks.map((feedback, index) => (
          <motion.div
            key={feedback._id}
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -20, scale: 0.95 }}
            transition={{ 
              delay: index * 0.1, 
              duration: 0.5,
              type: "spring",
              stiffness: 100
            }}
            layout
          >
            <FeedbackCard feedback={feedback} />
          </motion.div>
        ))}
      </AnimatePresence>
    </motion.div>
  )
} 