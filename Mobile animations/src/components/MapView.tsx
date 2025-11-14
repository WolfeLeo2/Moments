import { Menu, Search, User } from 'lucide-react';
import { StackedThumbnail } from './StackedThumbnail';
import { moments, Moment } from '../App';

interface MapViewProps {
  onMomentClick: (moment: Moment, position: { x: number; y: number }) => void;
  selectedMoment: Moment | null;
}

export function MapView({ onMomentClick, selectedMoment }: MapViewProps) {
  return (
    <div className="absolute inset-0 bg-[#E5E3DF]">
      {/* Map Background - styled to look like a map */}
      <div 
        className="absolute inset-0 bg-gradient-to-br from-[#AAD3DF] via-[#E5E3DF] to-[#D4E5D4] transition-all duration-500"
        style={{
          backgroundImage: `
            linear-gradient(rgba(170, 211, 223, 0.3) 1px, transparent 1px),
            linear-gradient(90deg, rgba(170, 211, 223, 0.3) 1px, transparent 1px)
          `,
          backgroundSize: '40px 40px',
          filter: selectedMoment ? 'blur(8px)' : 'blur(0px)',
          transform: selectedMoment ? 'scale(1.05)' : 'scale(1)',
          pointerEvents: selectedMoment ? 'none' : 'auto',
        }}
      >
        {/* Map labels overlay */}
        <div className="absolute inset-0 pointer-events-none">
          <div className="absolute top-[140px] left-[40px] opacity-40">
            <div className="tracking-wider text-[#6B8E9C]">West New</div>
            <div className="tracking-wider text-[#6B8E9C]">York</div>
          </div>
          <div className="absolute top-[180px] left-[160px] tracking-wider text-[#000000] opacity-30">
            NEW YORK
          </div>
          <div className="absolute bottom-[180px] left-[30px] tracking-wider text-[#6B8E9C] opacity-40">
            FINANCIAL
          </div>
          <div className="absolute bottom-[160px] left-[30px] tracking-wider text-[#6B8E9C] opacity-40">
            DISTRICT
          </div>
        </div>

        {/* Simulated map roads/water */}
        <div className="absolute top-0 left-[60px] w-[140px] h-full bg-gradient-to-b from-[#8FC5DD] to-[#AAD3DF] opacity-70"></div>
        <div className="absolute top-[200px] left-0 w-full h-[2px] bg-[#C5C5C5] opacity-40 rotate-12"></div>
        <div className="absolute top-[350px] left-0 w-full h-[2px] bg-[#C5C5C5] opacity-40 -rotate-6"></div>
        <div className="absolute top-[500px] left-0 w-full h-[2px] bg-[#C5C5C5] opacity-40 rotate-3"></div>
      </div>

      {/* Top Bar */}
      <div className="absolute top-0 left-0 right-0 h-16 bg-white/95 backdrop-blur-md shadow-sm z-20 flex items-center justify-between px-4">
        <button className="w-10 h-10 flex items-center justify-center">
          <Menu className="w-6 h-6 text-gray-800" />
        </button>
        <h1 className="tracking-wide text-gray-900">Moments</h1>
        <div className="flex items-center gap-3">
          <button className="w-10 h-10 flex items-center justify-center">
            <Search className="w-6 h-6 text-gray-800" />
          </button>
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-purple-400 to-pink-500 flex items-center justify-center">
            <User className="w-5 h-5 text-white" />
          </div>
        </div>
      </div>

      {/* Map Markers */}
      <div className="absolute inset-0 z-10">
        {moments.map((moment) => (
          <StackedThumbnail
            key={moment.id}
            moment={moment}
            onClick={onMomentClick}
            isSelected={selectedMoment?.id === moment.id}
          />
        ))}
      </div>

      {/* FAB Button */}
      <div className="absolute bottom-8 left-1/2 -translate-x-1/2 z-20 flex flex-col items-center gap-2">
        <button className="w-16 h-16 rounded-full bg-[#306BFF] shadow-lg hover:shadow-xl transition-shadow flex items-center justify-center">
          <div className="w-6 h-6 relative">
            <div className="absolute inset-0 flex items-center justify-center text-white">+</div>
          </div>
        </button>
        <span className="text-[#306BFF] tracking-wide">New Moment</span>
      </div>
    </div>
  );
}