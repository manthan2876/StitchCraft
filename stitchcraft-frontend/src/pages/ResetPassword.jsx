import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import supabase from '../services/supabase';
import { GiScissors, GiPadlock } from 'react-icons/gi';
import { MdCheckCircleOutline, MdErrorOutline, MdVisibility, MdVisibilityOff } from 'react-icons/md';
import { validatePassword } from '../utils/formValidators';

export const ResetPassword = () => {
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
  const [isSuccess, setIsSuccess] = useState(false);
  const [hasValidSession, setHasValidSession] = useState(true);
  const [isCheckingSession, setIsCheckingSession] = useState(true);
  const [shake, setShake] = useState(false);
  const { resetPassword, loading } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    let mounted = true;

    // Check if a recovery session exists via Supabase Auth
    const checkSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      
      // Also check if the URL hash contains access_token from password recovery redirect
      const hash = window.location.hash;
      const isRecoveryHash = hash.includes('type=recovery') || hash.includes('access_token=');

      if (!session && !isRecoveryHash) {
        if (mounted) setHasValidSession(false);
      } else {
        if (mounted) setHasValidSession(true);
      }
      if (mounted) setIsCheckingSession(false);
    };

    checkSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'PASSWORD_RECOVERY' || session) {
        if (mounted) {
          setHasValidSession(true);
          setIsCheckingSession(false);
        }
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    const errs = {};
    const passErr = validatePassword(password);
    if (passErr) errs.password = passErr;

    if (!confirmPassword) {
      errs.confirmPassword = 'Confirm password is required';
    } else if (password !== confirmPassword) {
      errs.confirmPassword = 'Passwords do not match';
    }

    if (Object.keys(errs).length > 0) {
      setFieldErrors(errs);
      setErrorMsg('Please correct the errors below.');
      setShake(true);
      setTimeout(() => setShake(false), 500);
      return;
    }

    try {
      await resetPassword(password);
      setIsSuccess(true);
    } catch (err) {
      setErrorMsg(err.message || 'Failed to reset password. The link may have expired.');
      setShake(true);
      setTimeout(() => setShake(false), 500);
    }
  };

  return (
    <div className="w-screen h-screen bg-bg-primary flex flex-col items-center justify-center p-4 select-none">
      <div
        className={`w-full max-w-[420px] bg-bg-secondary rounded-2xl border border-border-subtle p-8 shadow-theme-md transition-all duration-300
          ${shake ? 'animate-bounce' : ''}`}
      >
        <div className="flex flex-col items-center gap-2 mb-6">
          <div className="w-12 h-12 rounded-xl bg-color-accent-purple flex items-center justify-center text-white shadow-sm">
            <GiScissors className="w-6 h-6 transform -rotate-45" />
          </div>
          <h1 className="text-xl font-bold text-text-main mt-2 tracking-wide">StitchCraft ERP</h1>
          <p className="text-[10px] text-text-muted font-bold tracking-wider uppercase">Set New Password</p>
        </div>

        {isSuccess ? (
          <div className="flex flex-col items-center text-center py-4">
            <div className="w-14 h-14 rounded-full bg-color-accent-green/15 text-color-accent-green flex items-center justify-center mb-4">
              <MdCheckCircleOutline className="w-8 h-8" />
            </div>
            <h2 className="text-lg font-bold text-text-main mb-2">Password Reset Complete!</h2>
            <p className="text-xs text-text-muted leading-relaxed mb-6">
              Your password has been securely updated. You can now sign in with your new credentials.
            </p>
            <button
              onClick={() => navigate('/login')}
              className="w-full py-3 bg-color-accent-purple hover:bg-color-accent-purple-hover text-white font-medium rounded-lg text-sm text-center transition-all shadow-sm cursor-pointer"
            >
              Go to Sign In
            </button>
          </div>
        ) : isCheckingSession ? (
          <div className="flex flex-col items-center justify-center py-8">
            <div className="w-6 h-6 border-2 border-color-accent-purple border-t-transparent rounded-full animate-spin mb-3"></div>
            <p className="text-xs text-text-muted">Verifying recovery link...</p>
          </div>
        ) : !hasValidSession ? (
          <div className="flex flex-col items-center text-center py-4">
            <div className="w-14 h-14 rounded-full bg-color-accent-pink/15 text-color-accent-pink flex items-center justify-center mb-4">
              <MdErrorOutline className="w-8 h-8" />
            </div>
            <h2 className="text-base font-bold text-text-main mb-2">Invalid or Expired Link</h2>
            <p className="text-xs text-text-muted leading-relaxed mb-6">
              The password reset link is invalid or has already expired. Please request a new link to reset your password.
            </p>
            <Link
              to="/forgot-password"
              className="w-full py-3 bg-color-accent-purple hover:bg-color-accent-purple-hover text-white font-medium rounded-lg text-sm text-center transition-all shadow-sm"
            >
              Request New Link
            </Link>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="w-full flex flex-col items-center">
            <p className="text-xs text-text-muted text-center mb-6 leading-relaxed">
              Create a new secure password for your account (minimum 6 characters).
            </p>

            <div className="flex flex-col gap-4 w-full">
              <div className="flex flex-col gap-1.5 text-left">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">New Password</label>
                <div className="relative">
                  <GiPadlock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-5 h-5" />
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => {
                      setPassword(e.target.value);
                      setErrorMsg('');
                      setFieldErrors(prev => ({ ...prev, password: '' }));
                    }}
                    placeholder="••••••••"
                    className={`w-full pl-11 pr-11 py-3 bg-bg-input border rounded-lg text-text-main placeholder:text-text-muted/40 outline-none text-sm transition-all
                      ${fieldErrors.password ? 'border-color-accent-pink' : 'border-border-subtle focus:border-color-accent-purple'}`}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(prev => !prev)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-main transition-colors cursor-pointer"
                    aria-label={showPassword ? "Hide password" : "Show password"}
                  >
                    {showPassword ? <MdVisibilityOff className="w-5 h-5" /> : <MdVisibility className="w-5 h-5" />}
                  </button>
                </div>
                {fieldErrors.password && (
                  <span className="text-[11px] text-color-accent-pink font-semibold">{fieldErrors.password}</span>
                )}
              </div>

              <div className="flex flex-col gap-1.5 text-left">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Confirm New Password</label>
                <div className="relative">
                  <GiPadlock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-5 h-5" />
                  <input
                    type={showConfirmPassword ? 'text' : 'password'}
                    value={confirmPassword}
                    onChange={(e) => {
                      setConfirmPassword(e.target.value);
                      setErrorMsg('');
                      setFieldErrors(prev => ({ ...prev, confirmPassword: '' }));
                    }}
                    placeholder="••••••••"
                    className={`w-full pl-11 pr-11 py-3 bg-bg-input border rounded-lg text-text-main placeholder:text-text-muted/40 outline-none text-sm transition-all
                      ${fieldErrors.confirmPassword ? 'border-color-accent-pink' : 'border-border-subtle focus:border-color-accent-purple'}`}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(prev => !prev)}
                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-main transition-colors cursor-pointer"
                    aria-label={showConfirmPassword ? "Hide password" : "Show password"}
                  >
                    {showConfirmPassword ? <MdVisibilityOff className="w-5 h-5" /> : <MdVisibility className="w-5 h-5" />}
                  </button>
                </div>
                {fieldErrors.confirmPassword && (
                  <span className="text-[11px] text-color-accent-pink font-semibold">{fieldErrors.confirmPassword}</span>
                )}
              </div>

              {errorMsg && (
                <span className="text-xs text-color-accent-pink font-bold text-center animate-pulse mt-1">
                  {errorMsg}
                </span>
              )}

              <button
                type="submit"
                disabled={loading}
                className="mt-2 w-full py-3 bg-color-accent-purple hover:bg-color-accent-purple-hover text-white font-medium rounded-lg active:scale-98 transition-all duration-200 cursor-pointer disabled:opacity-50 text-sm shadow-sm"
              >
                {loading ? 'Updating Password...' : 'Reset Password'}
              </button>
            </div>

            <div className="mt-6 text-center">
              <Link
                to="/login"
                className="text-xs font-semibold text-color-accent-purple hover:underline transition-colors"
              >
                ← Back to Sign In
              </Link>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};

export default ResetPassword;

