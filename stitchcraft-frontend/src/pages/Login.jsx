import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { GiScissors, GiPadlock } from 'react-icons/gi';
import { MdEmail } from 'react-icons/md';
import { validateEmail, validateRequired } from '../utils/formValidators';

export const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
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
    const errs = {};
    const emailErr = validateEmail(email, true);
    if (emailErr) errs.email = emailErr;
    const passErr = validateRequired(password, 'Password');
    if (passErr) errs.password = passErr;

    if (Object.keys(errs).length > 0) {
      setFieldErrors(errs);
      setErrorMsg('Please correct the errors below.');
      setShake(true);
      setTimeout(() => setShake(false), 500);
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
                  onChange={(e) => { setEmail(e.target.value); setErrorMsg(''); setFieldErrors(prev => ({ ...prev, email: '' })); }}
                  placeholder="name@shop.com"
                  className={`w-full pl-11 pr-4 py-3 bg-bg-input border rounded-lg text-text-main placeholder:text-text-muted/40 outline-none text-sm transition-all
                    ${fieldErrors.email ? 'border-color-accent-pink' : 'border-border-subtle focus:border-color-accent-purple'}`}
                />
              </div>
              {fieldErrors.email && <span className="text-[11px] text-color-accent-pink font-semibold">{fieldErrors.email}</span>}
            </div>

            <div className="flex flex-col gap-1.5 text-left">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Password</label>
              <div className="relative">
                <GiPadlock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-5 h-5" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); setErrorMsg(''); setFieldErrors(prev => ({ ...prev, password: '' })); }}
                  placeholder="••••••••"
                  className={`w-full pl-11 pr-4 py-3 bg-bg-input border rounded-lg text-text-main placeholder:text-text-muted/40 outline-none text-sm transition-all
                    ${fieldErrors.password ? 'border-color-accent-pink' : 'border-border-subtle focus:border-color-accent-purple'}`}
                />
              </div>
              {fieldErrors.password && <span className="text-[11px] text-color-accent-pink font-semibold">{fieldErrors.password}</span>}
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
          </div>
        </form>
      </div>
    </div>
  );
};

export default Login;
