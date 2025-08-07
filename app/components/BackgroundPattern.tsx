export default function BackgroundPattern() {
  return (
    <div className="absolute inset-0 z-0 opacity-10">
      <svg
        className="w-full h-full"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 1000 1000"
        preserveAspectRatio="none"
      >
        <defs>
          <radialGradient id="grid" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#3b82f6" stopOpacity="0.1" />
            <stop offset="100%" stopColor="#1e293b" stopOpacity="0" />
          </radialGradient>
          <pattern id="dots" x="0" y="0" width="40" height="40" patternUnits="userSpaceOnUse">
            <circle cx="20" cy="20" r="1" fill="#64748b" fillOpacity="0.3" />
          </pattern>
        </defs>
        
        {/* Radial gradient background */}
        <rect width="100%" height="100%" fill="url(#grid)" />
        
        {/* Subtle dot pattern */}
        <rect width="100%" height="100%" fill="url(#dots)" />
        
        {/* Gradient overlays for depth */}
        <rect width="100%" height="100%" fill="url(#grid)" opacity="0.5" />
      </svg>
    </div>
  )
} 