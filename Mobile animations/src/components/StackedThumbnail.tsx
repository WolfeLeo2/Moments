import { motion } from 'motion/react';
import { Calendar } from 'lucide-react';
import { Moment } from '../App';
import { useState } from 'react';

interface StackedThumbnailProps {
  moment: Moment;
  onClick: (moment: Moment, position: { x: number; y: number }) => void;
  isSelected: boolean;
}

export function StackedThumbnail({ moment, onClick, isSelected }: StackedThumbnailProps) {
  const [isPressed, setIsPressed] = useState(false);

  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    onClick(moment, {
      x: rect.left + rect.width / 2,
      y: rect.top + rect.height / 2,
    });
  };

  // Generate unique, uneven transforms for each moment to create collage effect
  const getStackTransforms = (id: string) => {
    // Use ID to generate consistent but varied transforms
    const seed = id.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    
    return {
      back: {
        rotate: -12 + (seed % 8),
        x: -8 + (seed % 6),
        y: 10 + (seed % 5),
      },
      middle: {
        rotate: 8 - (seed % 10),
        x: 6 - (seed % 7),
        y: 6 + (seed % 4),
      },
      front: {
        rotate: -4 + (seed % 7),
      }
    };
  };

  const transforms = getStackTransforms(moment.id);

  // Parse date for calendar badge
  const parseDate = (dateString: string) => {
    const date = new Date(dateString);
    const month = date.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
    const day = date.getDate();
    return { month, day };
  };

  const { month, day } = parseDate(moment.date);

  // Generate mock avatars for contributors
  const avatarColors = [
    'from-blue-400 to-purple-500',
    'from-pink-400 to-orange-500',
    'from-green-400 to-teal-500',
  ];

  return (
    <motion.button
      layoutId={`moment-${moment.id}`}
      onClick={handleClick}
      onPointerDown={() => setIsPressed(true)}
      onPointerUp={() => setIsPressed(false)}
      onPointerCancel={() => setIsPressed(false)}
      className="absolute"
      style={{
        left: moment.position.x,
        top: moment.position.y,
        transformOrigin: 'center center',
      }}
      initial={false}
      animate={{
        opacity: isSelected ? 0 : 1,
        scale: isSelected ? 0.9 : (isPressed ? 0.95 : 1),
        y: isPressed ? -4 : 0,
      }}
      transition={{
        duration: 0.52,
        ease: [0.34, 1.56, 0.64, 1],
        scale: { duration: 0.15, ease: 'easeOut' },
        y: { duration: 0.15, ease: 'easeOut' },
      }}
    >
      <div className="relative">
        {/* Stacked cards effect - with peeking images */}
        <div className="relative w-[150px] h-[180px]">
          {/* Back card - with peeking image and shuffle animation */}
          <motion.div 
            className="absolute bg-white rounded-[14px] shadow-lg overflow-hidden"
            style={{
              inset: '0px -4px -6px 6px',
              zIndex: 1,
            }}
            animate={{
              rotate: transforms.back.rotate + (isPressed ? -3 : 0),
              x: transforms.back.x + (isPressed ? -6 : 0),
              y: transforms.back.y + (isPressed ? 4 : 0),
            }}
            transition={{
              type: 'spring',
              stiffness: 400,
              damping: 25,
            }}
          >
            <motion.div 
              layoutId={`moment-card-${moment.id}-2`}
              className="absolute inset-2 rounded-[10px] overflow-hidden"
            >
              {moment.photos[2] && (
                <img
                  src={moment.photos[2]}
                  alt=""
                  className="w-full h-full object-cover opacity-90"
                />
              )}
            </motion.div>
          </motion.div>
          
          {/* Middle card - with peeking image and shuffle animation */}
          <motion.div 
            className="absolute bg-white rounded-[14px] shadow-lg overflow-hidden"
            style={{
              inset: '0px 3px -4px -3px',
              zIndex: 2,
            }}
            animate={{
              rotate: transforms.middle.rotate + (isPressed ? 4 : 0),
              x: transforms.middle.x + (isPressed ? 7 : 0),
              y: transforms.middle.y + (isPressed ? 3 : 0),
            }}
            transition={{
              type: 'spring',
              stiffness: 400,
              damping: 25,
            }}
          >
            <motion.div 
              layoutId={`moment-card-${moment.id}-1`}
              className="absolute inset-2 rounded-[10px] overflow-hidden"
            >
              {moment.photos[1] && (
                <img
                  src={moment.photos[1]}
                  alt=""
                  className="w-full h-full object-cover opacity-90"
                />
              )}
            </motion.div>
          </motion.div>
          
          {/* Front card with main image - slightly rotated */}
          <motion.div 
            layoutId={`moment-card-${moment.id}-0`}
            className="absolute inset-0 bg-white rounded-[14px] p-2.5 shadow-xl"
            animate={{
              rotate: transforms.front.rotate,
            }}
            style={{
              zIndex: 3,
            }}
          >
            <div className="relative w-full h-full rounded-[10px] overflow-hidden">
              <img
                src={moment.photos[0]}
                alt={moment.title}
                className="w-full h-full object-cover"
              />
              
              {/* Badge (optional content badge) */}
              {moment.badge && (
                <div className="absolute top-2 left-2 bg-[#306BFF] text-white px-2.5 py-1 rounded-full text-[10px] tracking-wider shadow-md">
                  {moment.badge}
                </div>
              )}
            </div>
          </motion.div>
          
          {/* Calendar Date Badge - floats on top of entire stack */}
          <motion.div 
            className="absolute -top-1 -right-1 bg-white rounded-lg shadow-lg overflow-hidden border-2 border-white"
            style={{
              zIndex: 10,
            }}
            animate={{
              scale: isPressed ? 0.95 : 1,
            }}
            transition={{
              type: 'spring',
              stiffness: 400,
              damping: 25,
            }}
          >
            <div className="bg-red-500 text-white px-2 py-0.5 flex items-center justify-center gap-1">
              <Calendar className="w-2.5 h-2.5" />
              <span className="text-[9px] tracking-wider">{month}</span>
            </div>
            <div className="bg-white text-gray-900 px-2 py-1 text-center">
              <div className="leading-none">{day}</div>
            </div>
          </motion.div>

          {/* Avatar Stack - floats on top of entire stack */}
          <motion.div 
            layoutId={`moment-avatars-${moment.id}`}
            className="absolute -bottom-2 -left-2 flex items-center"
            style={{
              zIndex: 10,
            }}
            animate={{
              scale: isPressed ? 0.95 : 1,
            }}
            transition={{
              type: 'spring',
              stiffness: 400,
              damping: 25,
            }}
          >
            {avatarColors.slice(0, 3).map((colors, index) => (
              <div
                key={index}
                className={`w-8 h-8 rounded-full bg-gradient-to-br ${colors} border-2 border-white shadow-md -mr-2`}
                style={{
                  zIndex: 3 - index,
                }}
              />
            ))}
          </motion.div>
        </div>

        {/* Title Label - Bottom */}
        <div className="mt-3 text-center">
          <div className="bg-[#306BFF] text-white px-4 py-1.5 rounded-lg inline-block tracking-[0.15em] shadow-md">
            {moment.title}
          </div>
        </div>
      </div>
    </motion.button>
  );
}