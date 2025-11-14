import { useState } from 'react';
import { AnimatePresence } from 'motion/react';
import { MapView } from './components/MapView';
import { MomentDetail } from './components/MomentDetail';

export interface Moment {
  id: string;
  title: string;
  location: string;
  photoCount: number;
  date: string;
  photos: string[];
  position: { x: number; y: number };
  badge?: string;
}

export const moments: Moment[] = [
  {
    id: 'place-of-power',
    title: 'PLACE OF POWER',
    location: 'Midtown Manhattan',
    photoCount: 87,
    date: 'May 25, 2024',
    photos: [
      'https://images.unsplash.com/photo-1588384153148-ebd739ac430c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdGF0dWUlMjBvZiUyMGxpYmVydHl8ZW58MXx8fHwxNzYyNzkwNzkwfDA&ixlib=rb-4.1.0&q=80&w=1080',
      'https://images.unsplash.com/photo-1568602879745-3285bf3547db?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjZW50cmFsJTIwcGFyayUyMG55Y3xlbnwxfHx8fDE3NjI3OTg5MDJ8MA&ixlib=rb-4.1.0&q=80&w=1080',
      'https://images.unsplash.com/photo-1609945648638-cefddce6e6d8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYW5oYXR0YW4lMjBza3lsaW5lfGVufDF8fHx8MTc2Mjc4NDM3OHww&ixlib=rb-4.1.0&q=80&w=1080',
      'https://images.unsplash.com/photo-1573261658953-8b29e144d1af?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxicm9va2x5biUyMGJyaWRnZXxlbnwxfHx8fDE3NjI3OTA3OTB8MA&ixlib=rb-4.1.0&q=80&w=1080',
    ],
    position: { x: 195, y: 380 },
    badge: 'Cool Statue'
  },
  {
    id: 'sunset',
    title: 'SUNSET',
    location: 'Santa Monica',
    photoCount: 42,
    date: 'Jun 12, 2024',
    photos: [
      'https://images.unsplash.com/photo-1616036740257-9449ea1f6605?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdW5zZXQlMjBiZWFjaHxlbnwxfHx8fDE3NjI3MTA4NTJ8MA&ixlib=rb-4.1.0&q=80&w=1080',
      'https://images.unsplash.com/photo-1613070561201-b0dccb982856?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYWxpZm9ybmlhJTIwYmVhY2h8ZW58MXx8fHwxNzYyNzk4OTAzfDA&ixlib=rb-4.1.0&q=80&w=1080',
      'https://images.unsplash.com/photo-1670811456186-e73d0ace9454?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwYWxtJTIwdHJlZXMlMjBzdW5zZXR8ZW58MXx8fHwxNzYyNzg5Mzg1fDA&ixlib=rb-4.1.0&q=80&w=1080',
    ],
    position: { x: 195, y: 630 },
  },
  {
    id: 'brooklyn',
    title: 'BROOKLYN',
    location: 'Brooklyn',
    photoCount: 53,
    date: 'Apr 8, 2024',
    photos: [
      'https://images.unsplash.com/photo-1573261658953-8b29e144d1af?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxicm9va2x5biUyMGJyaWRnZXxlbnwxfHx8fDE3NjI3OTA3OTB8MA&ixlib=rb-4.1.0&q=80&w=1080',
      'https://images.unsplash.com/photo-1609945648638-cefddce6e6d8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYW5oYXR0YW4lMjBza3lsaW5lfGVufDF8fHx8MTc2Mjc4NDM3OHww&ixlib=rb-4.1.0&q=80&w=1080',
      'https://images.unsplash.com/photo-1568602879745-3285bf3547db?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjZW50cmFsJTIwcGFyayUyMG55Y3xlbnwxfHx8fDE3NjI3OTg5MDJ8MA&ixlib=rb-4.1.0&q=80&w=1080',
    ],
    position: { x: 280, y: 280 },
  },
  {
    id: 'times-square',
    title: 'TIMES SQUARE',
    location: 'Manhattan',
    photoCount: 96,
    date: 'Mar 15, 2024',
    photos: [
      'https://images.unsplash.com/photo-1595901688281-9cef114adb0b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0aW1lcyUyMHNxdWFyZXxlbnwxfHx8fDE3NjI3OTA3OTF8MA&ixlib=rb-4.1.0&q=80&w=1080',
      'https://images.unsplash.com/photo-1609945648638-cefddce6e6d8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtYW5oYXR0YW4lMjBza3lsaW5lfGVufDF8fHx8MTc2Mjc4NDM3OHww&ixlib=rb-4.1.0&q=80&w=1080',
      'https://images.unsplash.com/photo-1588384153148-ebd739ac430c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdGF0dWUlMjBvZiUyMGxpYmVydHl8ZW58MXx8fHwxNzYyNzkwNzkwfDA&ixlib=rb-4.1.0&q=80&w=1080',
    ],
    position: { x: 110, y: 250 },
    badge: 'WOW'
  },
];

export default function App() {
  const [selectedMoment, setSelectedMoment] = useState<Moment | null>(null);
  const [clickPosition, setClickPosition] = useState<{ x: number; y: number } | null>(null);

  const handleMomentClick = (moment: Moment, position: { x: number; y: number }) => {
    setClickPosition(position);
    setSelectedMoment(moment);
  };

  const handleBack = () => {
    setSelectedMoment(null);
  };

  return (
    <div className="relative w-[390px] h-[844px] mx-auto bg-white overflow-hidden">
      <MapView 
        onMomentClick={handleMomentClick} 
        selectedMoment={selectedMoment}
      />
      <AnimatePresence>
        {selectedMoment && clickPosition && (
          <MomentDetail 
            moment={selectedMoment} 
            onBack={handleBack}
            clickPosition={clickPosition}
          />
        )}
      </AnimatePresence>
    </div>
  );
}