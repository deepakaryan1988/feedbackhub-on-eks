import { motion } from 'framer-motion'
import { spinnerRotate } from '../lib/animations'

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg'
  className?: string
}

export default function LoadingSpinner({ size = 'md', className = '' }: LoadingSpinnerProps) {
  const sizeClasses = {
    sm: 'w-4 h-4',
    md: 'w-6 h-6',
    lg: 'w-8 h-8'
  }

  return (
    <motion.div
      className={`${sizeClasses[size]} border-2 border-neutral-400 border-t-blue-500 rounded-full ${className}`}
      variants={spinnerRotate}
      animate="animate"
    />
  )
} 