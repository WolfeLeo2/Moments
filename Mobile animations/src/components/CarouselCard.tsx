import { motion } from 'motion/react';

interface CarouselCardProps {
  photo: string;
  index: number;
  momentId: string;
  badge?: string;
  clickPosition: { x: number; y: number };
  totalPhotos: number;
  isCentered: boolean;
}

export function CarouselCard({ photo, index, momentId, badge, clickPosition, totalPhotos, isCentered }: CarouselCardProps) {
  // All cards start from the same stack position (click position)
  const initialX = clickPosition.x - 195;
  const initialY = clickPosition.y - 400;
  
  // Staggered delay for each card
  const baseDelay = index * 0.08;

  // Handwritten-style captions
  const captions = [
    "what a view! ✨",
    "perfect moment",
    "can't wait to go back",
    "vibes on point",
    "best day ever!",
  ];
  
  const caption = captions[index % captions.length];
  
  return (
    <div
      className="relative flex-shrink-0"
      style={{
        width: 240,
        height: 300,
        scrollSnapAlign: 'center',
      }}
    >
      {/* Card with Polaroid Style and depth effect */}
      <motion.div 
        layoutId={`moment-card-${momentId}-${index}`}
        className="w-full h-full bg-white rounded-[20px] p-3 shadow-[0_8px_24px_rgba(0,0,0,0.15)]"
        initial={{
          x: initialX,
          y: initialY,
          rotate: index === 0 ? 0 : index === 1 ? -8 : 8,
          scale: 0.18,
        }}
        animate={{
          x: 0,
          y: 0,
          rotate: 0,
          scale: isCentered ? 1 : 0.88,
        }}
        exit={{
          x: initialX,
          y: initialY,
          rotate: index === 0 ? 0 : index === 1 ? -8 : 8,
          scale: 0.18,
        }}
        transition={{
          type: 'spring',
          stiffness: 260,
          damping: 20,
          mass: 1.2,
          delay: baseDelay,
          scale: isCentered ? {
            type: 'spring',
            stiffness: 260,
            damping: 20,
            mass: 1.2,
            delay: baseDelay,
          } : {
            duration: 0.35,
            ease: [0.25, 0.1, 0.25, 1],
          }
        }}
        style={{
          transformStyle: 'preserve-3d',
          zIndex: isCentered ? 10 : 1,
        }}
      >
        <motion.div 
          className="relative w-full h-[220px] rounded-[16px] overflow-hidden mb-3"
          animate={{
            y: isCentered ? 0 : 20,
            rotateY: isCentered ? 0 : 8,
          }}
          transition={{
            duration: 0.35,
            ease: [0.25, 0.1, 0.25, 1],
          }}
        >
          <motion.img
            src={photo}
            alt={`Photo ${index + 1}`}
            className="w-full h-full object-cover"
            initial={{ scale: 1.1 }}
            animate={{ scale: isCentered ? 1 : 1.05 }}
            transition={{ duration: 0.5, ease: 'easeOut' }}
          />
          {badge && index === 0 && (
            <motion.div
              initial={{ scale: 0, rotate: -20 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{
                type: 'spring',
                stiffness: 200,
                damping: 15,
                delay: 0.5,
              }}
              className="absolute top-3 right-3 bg-[#306BFF] text-white px-3 py-1.5 rounded-full tracking-wider shadow-lg"
            >
              {badge}
            </motion.div>
          )}
          
          {/* Micro-interaction: Pulse on center */}
          {isCentered && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: [0, 0.3, 0] }}
              transition={{
                duration: 1.5,
                ease: 'easeInOut',
              }}
              className="absolute inset-0 border-4 border-[#306BFF] rounded-[16px] pointer-events-none"
            />
          )}
        </motion.div>
        
        {/* Handwritten-style caption */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{
            delay: baseDelay + 0.3,
            duration: 0.4,
          }}
          className="px-2"
        >
          <p 
            className="text-gray-700 text-center italic"
            style={{
              fontFamily: "'Caveat', cursive",
              fontSize: '18px',
              lineHeight: '1.2',
            }}
          >
            {caption}
          </p>
        </motion.div>
      </motion.div>
    </div>
  );
}
