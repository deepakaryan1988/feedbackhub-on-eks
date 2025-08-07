import { motion } from 'framer-motion'
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
        initial="hidden"
        animate="visible"
        variants={{
          hidden: { opacity: 0 },
          visible: {
            opacity: 1,
            transition: {
              staggerChildren: 0.1
            }
          }
        }}
      >
        {[...Array(3)].map((_, i) => (
          <motion.div 
            key={i} 
            className="bg-card border border-border p-6 rounded-lg animate-pulse"
            variants={{
              hidden: { opacity: 0, y: 20 },
              visible: { opacity: 1, y: 0 }
            }}
          >
            <div className="h-4 bg-muted rounded w-1/4 mb-3"></div>
            <div className="h-4 bg-muted rounded w-full mb-2"></div>
            <div className="h-3 bg-muted rounded w-3/4"></div>
          </motion.div>
        ))}
      </motion.div>
    )
  }

  if (feedbacks.length === 0) {
    return <EmptyState />
  }

  return (
    <motion.div 
      className="space-y-4"
      initial="hidden"
      animate="visible"
      variants={{
        hidden: { opacity: 0 },
        visible: {
          opacity: 1,
          transition: {
            staggerChildren: 0.1
          }
        }
      }}
    >
      {feedbacks.map((feedback, index) => (
        <motion.div
          key={feedback._id}
          variants={{
            hidden: { opacity: 0, y: 20 },
            visible: { opacity: 1, y: 0 }
          }}
          transition={{ delay: index * 0.1 }}
        >
          <FeedbackCard feedback={feedback} />
        </motion.div>
      ))}
    </motion.div>
  )
} 