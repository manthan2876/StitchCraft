import React from 'react';
import { useNavigate } from 'react-router-dom';
import Button from '../components/common/Button';
import { GiScissors } from 'react-icons/gi';

export const NotFound = () => {
  const navigate = useNavigate();

  return (
    <div className="w-screen h-screen bg-bg-primary flex flex-col items-center justify-center p-6 text-center select-none">
      
      <div className="relative mb-8 flex items-center justify-center">
        <div className="w-24 h-24 rounded-full bg-bg-secondary border border-white/10 flex items-center justify-center text-[#ff5c97] shadow-xl">
          <svg className="w-14 h-14 text-[#ff5c97] animate-bounce" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M6 3h12M6 21h12M8 3v18M16 3v18M8 6h8M8 10h8M8 14h8M8 18h8" />
          </svg>
        </div>
        
        <div className="absolute right-[-40px] top-[-20px] w-12 h-12 rounded-xl bg-color-accent-purple flex items-center justify-center text-white shadow-lg shadow-color-accent-purple/20 rotate-12">
          <GiScissors className="w-6 h-6 transform -rotate-45" />
        </div>
      </div>

      <h1 className="text-7xl font-black text-white tracking-tight">404</h1>
      <h2 className="text-xl font-bold text-color-accent-pink tracking-wider uppercase mt-2">Stitch Pattern Snapped</h2>
      <p className="text-sm text-text-muted mt-3 max-w-[320px] leading-relaxed">
        The page you are looking for has been cut from the final fabric or doesn't exist in our pattern directory!
      </p>

      <Button 
        variant="primary" 
        onClick={() => navigate('/dashboard')}
        className="mt-8 cursor-pointer"
      >
        Return to Dashboard
      </Button>

    </div>
  );
};

export default NotFound;
