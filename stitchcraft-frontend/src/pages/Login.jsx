import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { GiScissors, GiPadlock } from 'react-icons/gi';
import { MdEmail } from 'react-icons/md';

export const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [shake, setShake] = useState(false);
  const { login, loading, user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (user) {
      navigate('/dashboard');
    }
  }, [user, navigate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      setErrorMsg('Please fill in all fields.');
      return;
    }

    try {
      await login(email, password);
      navigate('/dashboard');
    } catch (err) {
      setErrorMsg(err.message);
      setShake(true);
      setTimeout(() => setShake(false), 500);
    }
  };

  return (
    <div className="w-screen h-screen bg-bg-primary flex flex-col items-center justify-center p-4 select-none">
      <div
        className={`w-full max-w-[400px] bg-bg-secondary rounded-2xl border border-border-subtle p-8 shadow-theme-md transition-all duration-300
          ${shake ? 'animate-bounce' : ''}`}
      >
        <form onSubmit={handleSubmit} className="w-full flex flex-col items-center">
          <div className="flex flex-col items-center gap-2 mb-6">
            <div className="w-12 h-12 rounded-xl bg-color-accent-purple flex items-center justify-center text-white shadow-sm">
              <GiScissors className="w-6 h-6 transform -rotate-45" />
            </div>
            <h1 className="text-xl font-bold text-text-main mt-2 tracking-wide">StitchCraft ERP</h1>
            <p className="text-[10px] text-text-muted font-bold tracking-wider uppercase">Masterji Shop Portal</p>
          </div>

          <div className="flex flex-col gap-4 w-full">
            <div className="flex flex-col gap-1.5 text-left">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Email Address</label>
              <div className="relative">
                <MdEmail className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-5 h-5" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); setErrorMsg(''); }}
                  placeholder="name@shop.com"
                  className="w-full pl-11 pr-4 py-3 bg-bg-input border border-border-subtle rounded-lg text-text-main placeholder:text-text-muted/40 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>
            </div>

            <div className="flex flex-col gap-1.5 text-left">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Password</label>
              <div className="relative">
                <GiPadlock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-5 h-5" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); setErrorMsg(''); }}
                  placeholder="••••••••"
                  className="w-full pl-11 pr-4 py-3 bg-bg-input border border-border-subtle rounded-lg text-text-main placeholder:text-text-muted/40 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>
            </div>

            {errorMsg && (
              <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse mt-1">
                {errorMsg}
              </span>
            )}

            <button
              type="submit"
              disabled={loading}
              className="mt-4 w-full py-3 bg-color-accent-purple hover:bg-color-accent-purple-hover text-white font-medium rounded-lg active:scale-98 transition-all duration-200 cursor-pointer disabled:opacity-50 text-sm shadow-sm"
            >
              {loading ? 'Logging in...' : 'Sign In'}
            </button>
          </div>

          <div className="mt-6 text-center flex flex-col gap-2">
            <span className="text-[11px] text-text-muted font-semibold tracking-wider">
              Don't have an account?{' '}
              <Link to="/signup" className="text-color-accent-purple font-bold hover:underline">
                Sign Up
              </Link>
            </span>
            <span className="text-[10px] text-text-muted/50 font-semibold tracking-wider">
              Demo: <strong className="text-text-muted/70">ramesh@stitchcraft.com</strong> / <strong className="text-text-muted/70">1234</strong>
            </span>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Login;
