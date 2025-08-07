import { motion } from 'framer-motion'
import { MessageSquare, Sparkles } from 'lucide-react'

export default function EmptyState() {
  return (
    <motion.div 
      className="text-center py-12"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: [0.25, 0.46, 0.45, 0.94] }}
    >
      <motion.div 
        className="w-20 h-20 mx-auto mb-6 rounded-full bg-gradient-to-br from-primary/10 to-primary/5 flex items-center justify-center"
        whileHover={{ scale: 1.05, rotate: 5 }}
        transition={{ duration: 0.2 }}
      >
        <MessageSquare className="w-10 h-10 text-primary" />
      </motion.div>
      
      <motion.h3 
        className="text-xl font-semibold text-foreground mb-2"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.1 }}
      >
        No feedback yet
      </motion.h3>
      
      <motion.p 
        className="text-muted-foreground mb-6 max-w-sm mx-auto"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
      >
        Be the first to share your thoughts! Your feedback helps us improve and create better experiences.
      </motion.p>

      <motion.div
        className="flex items-center justify-center space-x-2 text-xs text-muted-foreground"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
      >
        <Sparkles className="w-3 h-3" />
        <span>Your feedback makes a difference</span>
        <Sparkles className="w-3 h-3" />
      </motion.div>
    </motion.div>
  )
} 