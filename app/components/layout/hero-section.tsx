import { motion, useMotionValue, useTransform, useSpring, useAnimation } from 'framer-motion'
import { MessageSquare, ArrowRight, Sparkles, Users, Zap } from 'lucide-react'
import { useState, useEffect, useRef } from 'react'

export default function HeroSection() {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 })
  const [isGlitching, setIsGlitching] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)
  const mouseX = useMotionValue(0)
  const mouseY = useMotionValue(0)
  
  const features = [
    {
      icon: Zap,
      title: 'Lightning Fast',
      description: 'Submit feedback instantly with our optimized form'
    },
    {
      icon: Users,
      title: 'Community Driven',
      description: 'Join others in shaping the future of our platform'
    },
    {
      icon: Sparkles,
      title: 'Beautiful Design',
      description: 'Modern, accessible interface that delights users'
    }
  ]

  // Magnetic effect for the main button
  const buttonX = useTransform(mouseX, [-300, 300], [-20, 20])
  const buttonY = useTransform(mouseY, [-300, 300], [-20, 20])
  const buttonSpringX = useSpring(buttonX, { stiffness: 150, damping: 15 })
  const buttonSpringY = useSpring(buttonY, { stiffness: 150, damping: 15 })

  // Glitch effect timer
  useEffect(() => {
    const glitchInterval = setInterval(() => {
      setIsGlitching(true)
      setTimeout(() => setIsGlitching(false), 200)
    }, 3000)
    return () => clearInterval(glitchInterval)
  }, [])

  // Mouse tracking for magnetic effects
  const handleMouseMove = (e: React.MouseEvent) => {
    if (containerRef.current) {
      const rect = containerRef.current.getBoundingClientRect()
      const centerX = rect.left + rect.width / 2
      const centerY = rect.top + rect.height / 2
      mouseX.set(e.clientX - centerX)
      mouseY.set(e.clientY - centerY)
      setMousePosition({ x: e.clientX, y: e.clientY })
    }
  }

  // Floating particles
  const particles = Array.from({ length: 20 }, (_, i) => ({
    id: i,
    x: Math.random() * 100,
    y: Math.random() * 100,
    size: Math.random() * 4 + 2,
    duration: Math.random() * 20 + 10
  }))

  return (
    <motion.section 
      ref={containerRef}
      className="text-center py-16 md:py-24 relative overflow-hidden"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 1.2 }}
      onMouseMove={handleMouseMove}
    >
      {/* Floating Particles Background */}
      {particles.map((particle) => (
        <motion.div
          key={particle.id}
          className="absolute rounded-full pointer-events-none"
          style={{
            left: `${particle.x}%`,
            top: `${particle.y}%`,
            width: particle.size * 2, // Doubled the size
            height: particle.size * 2,
            background: `radial-gradient(circle, rgba(59, 130, 246, 0.8) 0%, rgba(59, 130, 246, 0.4) 50%, transparent 100%)`,
            boxShadow: `0 0 ${particle.size * 3}px rgba(59, 130, 246, 0.6), 0 0 ${particle.size * 6}px rgba(59, 130, 246, 0.3)`
          }}
          animate={{
            y: [0, -100, 0],
            x: [0, Math.random() * 50 - 25, 0],
            opacity: [0.6, 1, 0.6], // Increased opacity range
            scale: [0.8, 1.8, 0.8], // Increased scale range
            filter: [
              'brightness(1)',
              'brightness(1.5)',
              'brightness(1)'
            ]
          }}
          transition={{
            duration: particle.duration,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
      ))}

      {/* Main Heading with Glitch Effect */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3, duration: 0.8 }}
        className="mb-8 relative"
      >
        <div className="flex items-center justify-center space-x-3 mb-6">
          <motion.div 
            className="flex h-14 w-14 items-center justify-center rounded-xl bg-primary shadow-lg relative"
            whileHover={{ scale: 1.1, rotate: 5 }}
            transition={{ type: "spring", stiffness: 300 }}
            style={{
              x: buttonSpringX,
              y: buttonSpringY
            }}
          >
            <MessageSquare className="h-7 w-7 text-primary-foreground" />
            {/* Glitch overlay */}
            {isGlitching && (
              <motion.div
                className="absolute inset-0 bg-red-500 mix-blend-difference"
                initial={{ opacity: 0, x: -5 }}
                animate={{ opacity: 0.3, x: 5 }}
                transition={{ duration: 0.1, repeat: 5 }}
              />
            )}
          </motion.div>
          
          <motion.h1 
            className="text-4xl md:text-6xl font-bold text-foreground relative"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.5, duration: 0.8 }}
            style={{
              x: buttonSpringX,
              y: buttonSpringY
            }}
          >
            <span className="relative">
              FeedbackHub
              {/* Glitch text effect */}
              {isGlitching && (
                <>
                  <motion.span
                    className="absolute inset-0 text-red-500"
                    initial={{ x: -2, opacity: 0 }}
                    animate={{ x: 2, opacity: 0.8 }}
                    transition={{ duration: 0.1, repeat: 5 }}
                  >
                    FeedbackHub
                  </motion.span>
                  <motion.span
                    className="absolute inset-0 text-blue-500"
                    initial={{ x: 2, opacity: 0 }}
                    animate={{ x: -2, opacity: 0.6 }}
                    transition={{ duration: 0.1, repeat: 5, delay: 0.05 }}
                  >
                    FeedbackHub
                  </motion.span>
                </>
              )}
            </span>
          </motion.h1>
        </div>
        
        <motion.div 
          className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto leading-relaxed"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.7, duration: 0.8 }}
          style={{
            x: buttonSpringX,
            y: buttonSpringY
          }}
        >
          Share your thoughts, shape the future. A modern feedback platform built for the community.
        </motion.div>
      </motion.div>

      {/* CTA Button with Magnetic Effect */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.9, duration: 0.8 }}
        className="mb-12"
      >
        <motion.button
          className="inline-flex items-center space-x-3 bg-primary text-primary-foreground px-10 py-4 rounded-xl text-lg font-semibold hover:bg-primary/90 transition-all duration-300 shadow-lg hover:shadow-xl relative overflow-hidden"
          whileHover={{ scale: 1.05, y: -3 }}
          whileTap={{ scale: 0.95 }}
          onClick={() => document.getElementById('feedback-form')?.scrollIntoView({ behavior: 'smooth' })}
          style={{
            x: buttonSpringX,
            y: buttonSpringY
          }}
        >
          {/* Button background animation */}
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
          
          <span className="relative z-10">Get Started</span>
          <motion.div
            className="relative z-10"
            animate={{ x: [0, 5, 0] }}
            transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
          >
            <ArrowRight className="h-5 w-5" />
          </motion.div>
        </motion.button>
      </motion.div>

      {/* Features Grid with Explosive Animations */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.1, duration: 0.8 }}
        className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-4xl mx-auto"
      >
        {features.map((feature, index) => (
          <motion.div
            key={feature.title}
            initial={{ opacity: 0, y: 30, scale: 0.5, rotate: -180 }}
            animate={{ opacity: 1, y: 0, scale: 1, rotate: 0 }}
            transition={{ 
              delay: 1.3 + index * 0.15, 
              duration: 0.8,
              type: "spring",
              stiffness: 100,
              damping: 10
            }}
            className="text-center p-8 rounded-xl border border-border/50 hover:border-border hover:shadow-xl transition-all duration-300 group cursor-pointer relative overflow-hidden"
            whileHover={{ 
              y: -8, 
              scale: 1.02,
              rotateY: 15,
              rotateX: 5
            }}
            whileTap={{ scale: 0.95, rotate: 5 }}
          >
            {/* Hover background effect */}
            <motion.div
              className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-primary/10"
              initial={{ opacity: 0 }}
              whileHover={{ opacity: 1 }}
              transition={{ duration: 0.3 }}
            />
            
            <motion.div 
              className="flex h-16 w-16 items-center justify-center rounded-xl bg-primary/10 mx-auto mb-6 group-hover:bg-primary/20 transition-all duration-300 relative z-10"
              whileHover={{ 
                scale: 1.1, 
                rotate: 5,
                y: -5
              }}
            >
              <feature.icon className="h-8 w-8 text-primary group-hover:text-primary/80 transition-colors duration-300" />
            </motion.div>
            <h3 className="text-xl font-semibold text-foreground mb-3 group-hover:text-primary transition-colors duration-300 relative z-10">
              {feature.title}
            </h3>
            <p className="text-sm text-muted-foreground group-hover:text-foreground/80 transition-colors duration-300 relative z-10">
              {feature.description}
            </p>
          </motion.div>
        ))}
      </motion.div>

      {/* Stats with Wave Animation */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.8, duration: 0.8 }}
        className="mt-20 pt-8 border-t border-border/50"
      >
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 max-w-2xl mx-auto">
          {[
            { value: '100%', label: 'Uptime' },
            { value: '<100ms', label: 'Response Time' },
            { value: '24/7', label: 'Support' },
            { value: '∞', label: 'Scalability' }
          ].map((stat, index) => (
            <motion.div 
              key={stat.label}
              className="text-center group cursor-pointer relative"
              initial={{ opacity: 0, scale: 0.8, y: 50 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              transition={{ delay: 2.0 + index * 0.1, duration: 0.6, type: "spring" }}
              whileHover={{ 
                scale: 1.05,
                y: -10,
                rotateY: 10
              }}
            >
              {/* Wave effect on hover */}
              <motion.div
                className="absolute inset-0 bg-primary/5 rounded-full"
                initial={{ scale: 0, opacity: 0 }}
                whileHover={{ scale: 2, opacity: 0 }}
                transition={{ duration: 0.6 }}
              />
              
              <div className="text-3xl font-bold text-foreground group-hover:text-primary transition-colors duration-300 relative z-10">
                {stat.value}
              </div>
              <div className="text-sm text-muted-foreground group-hover:text-foreground/80 transition-colors duration-300 relative z-10">
                {stat.label}
              </div>
            </motion.div>
          ))}
        </div>
      </motion.div>
    </motion.section>
  )
} 