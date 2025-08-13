import { motion, useMotionValue, useTransform, useSpring } from 'framer-motion'
import { MessageSquare, Clock, User } from 'lucide-react'
import { Feedback } from '../../types/feedback'
import { useState, useEffect } from 'react'

interface FeedbackCardProps {
  feedback: Feedback
}

export default function FeedbackCard({ feedback }: FeedbackCardProps) {
  const [isHovered, setIsHovered] = useState(false)
  const [isGlitching, setIsGlitching] = useState(false)
  const mouseX = useMotionValue(0)
  const mouseY = useMotionValue(0)

  // Glitch effect randomly
  useEffect(() => {
    const glitchInterval = setInterval(() => {
      if (Math.random() > 0.7) {
        setIsGlitching(true)
        setTimeout(() => setIsGlitching(false), 150)
      }
    }, 2000)
    return () => clearInterval(glitchInterval)
  }, [])

  const formatDate = (date: Date | string) => {
    const dateObj = typeof date === 'string' ? new Date(date) : date
    const now = new Date()
    const diffInMs = now.getTime() - dateObj.getTime()
    const diffInMinutes = Math.floor(diffInMs / (1000 * 60))
    const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60))
    const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))
    
    if (diffInMinutes < 1) {
      return 'Just now'
    } else if (diffInMinutes < 60) {
      return `${diffInMinutes}m ago`
    } else if (diffInHours < 24) {
      return `${diffInHours}h ago`
    } else if (diffInDays < 7) {
      return `${diffInDays}d ago`
    } else {
      return dateObj.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      })
    }
  }

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect()
    const centerX = rect.left + rect.width / 2
    const centerY = rect.top + rect.height / 2
    mouseX.set(e.clientX - centerX)
    mouseY.set(e.clientY - centerY)
  }

  const rotateX = useTransform(mouseY, [-100, 100], [15, -15])
  const rotateY = useTransform(mouseX, [-100, 100], [-15, 15])
  const springRotateX = useSpring(rotateX, { stiffness: 100, damping: 10 })
  const springRotateY = useSpring(rotateY, { stiffness: 100, damping: 10 })

  return (
    <motion.div
      className="group cursor-pointer relative"
      onMouseMove={handleMouseMove}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      whileHover={{ 
        y: -8, 
        scale: 1.02,
        transition: { type: "spring", stiffness: 300, damping: 20 }
      }}
      whileTap={{ 
        scale: 0.95, 
        rotate: 5,
        transition: { type: "spring", stiffness: 400, damping: 10 }
      }}
      style={{
        rotateX: springRotateX,
        rotateY: springRotateY,
        transformStyle: "preserve-3d"
      }}
    >
      <motion.div 
        className="bg-card border border-border rounded-xl p-6 hover:border-border/60 hover:shadow-xl transition-all duration-300 relative overflow-hidden"
        style={{
          transformStyle: "preserve-3d"
        }}
      >
        {/* Morphing background effect */}
        <motion.div
          className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-primary/10"
          animate={{
            borderRadius: isHovered 
              ? ["60% 40% 30% 70% / 60% 30% 70% 40%", "30% 60% 70% 40% / 50% 60% 30% 60%"]
              : ["30% 60% 70% 40% / 50% 60% 30% 60%", "60% 40% 30% 70% / 60% 30% 70% 40%"]
          }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
        />

        {/* Glitch overlay */}
        {isGlitching && (
          <motion.div
            className="absolute inset-0 bg-red-500/20 mix-blend-difference z-10"
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 10 }}
            transition={{ duration: 0.1, repeat: 3 }}
          />
        )}

        {/* Floating particles around the card */}
        {isHovered && (
          <>
            {[...Array(5)].map((_, i) => (
              <motion.div
                key={i}
                className="absolute w-2 h-2 bg-primary/60 rounded-full pointer-events-none"
                style={{
                  left: `${20 + i * 15}%`,
                  top: `${30 + i * 10}%`
                }}
                initial={{ opacity: 0, scale: 0, y: 0 }}
                animate={{ 
                  opacity: [0, 1, 0], 
                  scale: [0, 1.5, 0],
                  y: [-20, -40, -20],
                  x: [0, Math.random() * 20 - 10, 0]
                }}
                transition={{ 
                  duration: 2, 
                  repeat: Infinity, 
                  delay: i * 0.2,
                  ease: "easeInOut"
                }}
              />
            ))}
          </>
        )}

        {/* Header */}
        <div className="flex items-start justify-between mb-4 relative z-20">
          <div className="flex items-center space-x-3">
            <motion.div 
              className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 group-hover:bg-primary/20 transition-all duration-300"
              whileHover={{ 
                scale: 1.2, 
                rotate: 15,
                y: -5
              }}
              animate={{
                rotate: isHovered ? [0, 5, -5, 0] : 0
              }}
              transition={{ duration: 2, repeat: Infinity }}
            >
              <User className="h-5 w-5 text-primary" />
            </motion.div>
            <div>
              <motion.h3 
                className="font-semibold text-foreground group-hover:text-primary transition-colors duration-300"
                animate={{
                  textShadow: isHovered 
                    ? ["0 0 5px rgba(59, 130, 246, 0.5)", "0 0 15px rgba(59, 130, 246, 0.8)", "0 0 5px rgba(59, 130, 246, 0.5)"]
                    : ["0 0 0px rgba(59, 130, 246, 0)", "0 0 0px rgba(59, 130, 246, 0)", "0 0 0px rgba(59, 130, 246, 0)"]
                }}
                transition={{ duration: 1, repeat: Infinity }}
              >
                {feedback.name}
              </motion.h3>
              <div className="flex items-center space-x-2 text-xs text-muted-foreground">
                <motion.div
                  animate={{ rotate: isHovered ? [0, 360] : 0 }}
                  transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                >
                  <Clock className="h-3 w-3" />
                </motion.div>
                <span>{formatDate(feedback.createdAt)}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Message */}
        <div className="space-y-3 relative z-20">
          <div className="flex items-start space-x-3">
            <motion.div
              animate={{ 
                rotate: isHovered ? [0, 10, -10, 0] : 0,
                scale: isHovered ? [1, 1.1, 1] : 1
              }}
              transition={{ duration: 1, repeat: Infinity }}
            >
              <MessageSquare className="h-5 w-5 text-primary/60 mt-0.5 flex-shrink-0 group-hover:text-primary transition-colors duration-300" />
            </motion.div>
            <motion.div 
              className="text-sm text-muted-foreground leading-relaxed group-hover:text-foreground/80 transition-colors duration-300"
              animate={{
                textShadow: isHovered 
                  ? ["0 0 2px rgba(255, 255, 255, 0.1)", "0 0 8px rgba(255, 255, 255, 0.3)", "0 0 2px rgba(255, 255, 255, 0.1)"]
                  : ["0 0 0px rgba(255, 255, 255, 0)", "0 0 0px rgba(255, 255, 255, 0)", "0 0 0px rgba(255, 255, 255, 0)"]
              }}
              transition={{ duration: 1.5, repeat: Infinity }}
            >
              {feedback.message}
            </motion.div>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-6 pt-4 border-t border-border/50 relative z-20">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3 text-xs text-muted-foreground">
              <motion.div 
                className="flex items-center space-x-1"
                animate={{ 
                  scale: isHovered ? [1, 1.1, 1] : 1,
                  rotate: isHovered ? [0, 5, -5, 0] : 0
                }}
                transition={{ duration: 1, repeat: Infinity }}
              >
                <motion.div 
                  className="w-2 h-2 rounded-full bg-green-500"
                  animate={{ 
                    scale: [1, 1.5, 1],
                    opacity: [0.5, 1, 0.5]
                  }}
                  transition={{ duration: 1, repeat: Infinity }}
                />
                <span>Received</span>
              </motion.div>
            </div>
            
            {/* Feedback Type Badge with morphing */}
            <motion.div
              className="px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-medium relative overflow-hidden"
              whileHover={{ scale: 1.1 }}
              animate={{
                borderRadius: isHovered 
                  ? ["50%", "30% 70% 70% 30% / 30% 30% 70% 70%"]
                  : ["30% 70% 70% 30% / 30% 30% 70% 70%", "50%"]
              }}
              transition={{ 
                type: "spring", 
                stiffness: 300,
                duration: 1, 
                repeat: Infinity, 
                ease: "easeInOut" 
              }}
            >
              <span className="relative z-10">Feedback</span>
              {isHovered && (
                <motion.div
                  className="absolute inset-0 bg-primary/20"
                  initial={{ scale: 0, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  exit={{ scale: 0, opacity: 0 }}
                  transition={{ duration: 0.3 }}
                />
              )}
            </motion.div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  )
} 