import { motion, useMotionValue, useTransform, PanInfo } from 'motion/react';
import { ChevronLeft, Settings, Zap, Type } from 'lucide-react';
import { Moment } from '../App';
import { CarouselCard } from './CarouselCard';
import { useEffect, useRef, useState } from 'react';

interface MomentDetailProps {
  moment: Moment;
  onBack: () => void;
  clickPosition: { x: number; y: number };
}

export function MomentDetail({ moment, onBack, clickPosition }: MomentDetailProps) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const [centerIndex, setCenterIndex] = useState(1); // Start at index 1 (center)
  const y = useMotionValue(0);
  const opacity = useTransform(y, [0, 200], [1, 0]);

  // Reorder photos: [1, 0, 2, 3, 4, ...] so front card (0) is in center
  const reorderedPhotos = [
    moment.photos[1], // Left (middle stack card)
    moment.photos[0], // Center (front stack card)
    moment.photos[2], // Right (back stack card)
    ...moment.photos.slice(3), // Rest of photos
  ].filter(Boolean); // Remove undefined if moment has < 3 photos

  // Map reordered index back to original index for layoutId
  const getOriginalIndex = (reorderedIndex: number) => {
    if (reorderedIndex === 0) return 1;
    if (reorderedIndex === 1) return 0;
    if (reorderedIndex === 2) return 2;
    return reorderedIndex;
  };

  // Handle scroll to update which card is centered
  useEffect(() => {
    const handleScroll = () => {
      if (!scrollRef.current) return;
      const scrollLeft = scrollRef.current.scrollLeft;
      const cardWidth = 240 + 16;
      const newIndex = Math.round(scrollLeft / cardWidth);
      setCenterIndex(newIndex);
    };

    const scrollEl = scrollRef.current;
    if (scrollEl) {
      scrollEl.addEventListener('scroll', handleScroll);
      
      // Scroll to center card on mount with smooth behavior
      setTimeout(() => {
        const cardWidth = 240 + 16;
        scrollEl.scrollTo({
          left: cardWidth * 1,
          behavior: 'smooth',
        });
      }, 100);
      
      return () => scrollEl.removeEventListener('scroll', handleScroll);
    }
  }, []);

  // Handle drag to close
  const handleDragEnd = (event: MouseEvent | TouchEvent | PointerEvent, info: PanInfo) => {
    if (info.offset.y > 150) {
      onBack();
    }
  };

  // Calculate circular mask size based on distance from click point
  const maxDistance = Math.sqrt(
    Math.max(
      clickPosition.x ** 2 + clickPosition.y ** 2,
      (390 - clickPosition.x) ** 2 + clickPosition.y ** 2,
      clickPosition.x ** 2 + (844 - clickPosition.y) ** 2,
      (390 - clickPosition.x) ** 2 + (844 - clickPosition.y) ** 2
    )
  );

  return (
    <motion.div
      className="absolute inset-0 z-30 pointer-events-none"
      style={{ y, opacity }}
      drag="y"
      dragConstraints={{ top: 0, bottom: 0 }}
      dragElastic={{ top: 0, bottom: 0.5 }}
      onDragEnd={handleDragEnd}
    >
      {/* Circular white background overlay that expands from click position */}
      <motion.div
        initial={{ 
          clipPath: `circle(0% at ${clickPosition.x}px ${clickPosition.y}px)`,
        }}
        animate={{ 
          clipPath: `circle(${maxDistance * 1.2}px at ${clickPosition.x}px ${clickPosition.y}px)`,
        }}
        exit={{ 
          clipPath: `circle(0% at ${clickPosition.x}px ${clickPosition.y}px)`,
        }}
        transition={{
          type: 'spring',
          stiffness: 200,
          damping: 24,
          mass: 1,
        }}
        className="absolute inset-0 bg-white pointer-events-auto"
      >
        {/* Top Bar - slides down */}
        <motion.div
          initial={{ opacity: 0, y: -40 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -40 }}
          transition={{
            type: 'spring',
            stiffness: 280,
            damping: 26,
            delay: 0.12,
          }}
          className="absolute top-0 left-0 right-0 h-16 bg-white shadow-sm z-20 flex items-center justify-between px-4"
        >
          <button 
            onClick={onBack}
            className="w-10 h-10 flex items-center justify-center active:scale-90 transition-transform"
          >
            <ChevronLeft className="w-6 h-6 text-gray-800" />
          </button>
          <h1 className="tracking-[0.15em] text-gray-900">{moment.title}</h1>
          <div className="flex items-center gap-3">
            <button className="w-10 h-10 flex items-center justify-center">
              <div className="w-3 h-3 rounded-full bg-[#306BFF]"></div>
            </button>
          </div>
        </motion.div>

        {/* Avatar Group - bounces in */}
        <motion.div
          layoutId={`moment-avatars-${moment.id}`}
          className="absolute top-20 left-6 flex items-center z-20"
        >
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 border-2 border-white -mr-3 z-30" />
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-pink-400 to-orange-500 border-2 border-white -mr-3 z-20" />
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-green-400 to-teal-500 border-2 border-white z-10" />
        </motion.div>

        {/* Content Area */}
        <div className="absolute top-40 left-0 right-0 bottom-0 flex flex-col">
          {/* Title Block - fades up */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            transition={{
              type: 'spring',
              stiffness: 260,
              damping: 24,
              delay: 0.16,
            }}
            className="px-6 mb-4"
          >
            <h2 className="tracking-[0.1em] mb-2">{moment.title}</h2>
            <div className="text-gray-500 tracking-wide">
              {moment.location} • {moment.photoCount} photos • {moment.date}
            </div>
          </motion.div>

          {/* Horizontal Scrollable Carousel */}
          <div className="relative flex-1 overflow-hidden">
            <div 
              ref={scrollRef}
              className="flex items-center gap-4 px-[75px] overflow-x-auto scrollbar-hide momentum-scroll pb-8 h-full"
              style={{
                scrollSnapType: 'x mandatory',
                WebkitOverflowScrolling: 'touch',
                perspective: '1200px',
              }}
            >
              {reorderedPhotos.map((photo, reorderedIndex) => {
                const originalIndex = getOriginalIndex(reorderedIndex);
                return (
                  <CarouselCard
                    key={`${moment.id}-photo-${originalIndex}`}
                    photo={photo}
                    index={originalIndex}
                    momentId={moment.id}
                    badge={originalIndex === 0 ? moment.badge : undefined}
                    clickPosition={clickPosition}
                    totalPhotos={moment.photos.length}
                    isCentered={centerIndex === reorderedIndex}
                  />
                );
              })}
            </div>
          </div>
        </div>

        {/* Bottom Toolbar - slides up */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 40 }}
          transition={{
            type: 'spring',
            stiffness: 260,
            damping: 24,
            delay: 0.24,
          }}
          className="absolute bottom-6 left-0 right-0 flex items-center justify-center gap-8 z-20 bg-white pt-4"
        >
          <motion.button 
            className="w-10 h-10 flex items-center justify-center"
            whileTap={{ scale: 0.85 }}
            transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          >
            <Settings className="w-6 h-6 text-gray-700" />
          </motion.button>
          <motion.button 
            className="w-10 h-10 flex items-center justify-center"
            whileTap={{ scale: 0.85 }}
            transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          >
            <Zap className="w-6 h-6 text-gray-700" />
          </motion.button>
          <motion.button 
            className="w-10 h-10 flex items-center justify-center"
            whileTap={{ scale: 0.85 }}
            transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          >
            <Type className="w-6 h-6 text-gray-700" />
          </motion.button>
          <motion.button 
            className="text-[#306BFF] tracking-wide"
            whileTap={{ scale: 0.95 }}
            transition={{ type: 'spring', stiffness: 500, damping: 30 }}
          >
            Preview
          </motion.button>
        </motion.div>
      </motion.div>
    </motion.div>
  );
}