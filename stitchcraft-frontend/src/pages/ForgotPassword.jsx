import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { useLanguage } from '../context/LanguageContext';
import { GiScissors } from 'react-icons/gi';
import { MdEmail, MdCheckCircleOutline } from 'react-icons/md';
import { validateEmail } from '../utils/formValidators';

export const ForgotPassword = () => {
  const { t } = useLanguage();
  const [email, setEmail] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [shake, setShake] = useState(false);
  const { forgotPassword, loading } = useAuth();

  const handleSubmit = async (e) => {
    e.preventDefault();
    const errs = {};
    const emailErr = validateEmail(email, true);
    if (emailErr) errs.email = emailErr;

    if (Object.keys(errs).length > 0) {
      setFieldErrors(errs);
      setErrorMsg('Please enter a valid email address.');
      setShake(true);
      setTimeout(() => setShake(false), 500);
      return;
    }

    try {
      await forgotPassword(email);
      setIsSubmitted(true);
    } catch (err) {
      setErrorMsg(err.message || 'Failed to send password reset email. Please try again.');
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
          <p className="text-[10px] text-text-muted font-bold tracking-wider uppercase">{t('forgotPasswordTitle')}</p>
        </div>

        {isSubmitted ? (
          <div className="flex flex-col items-center text-center py-4">
            <div className="w-14 h-14 rounded-full bg-color-accent-green/15 text-color-accent-green flex items-center justify-center mb-4">
              <MdCheckCircleOutline className="w-8 h-8" />
            </div>
            <h2 className="text-lg font-bold text-text-main mb-2">{t('checkYourEmail')}</h2>
            <p className="text-xs text-text-muted leading-relaxed mb-6">
              {(t('resetLinkSent') || 'We have sent a password reset link to your email. Follow the instructions in the email to set a new password.')}
            </p>
            <Link
              to="/login"
              className="w-full py-3 bg-color-accent-purple hover:bg-color-accent-purple-hover text-white font-medium rounded-lg text-sm text-center transition-all shadow-sm"
            >
              {t('backToSignIn')}
            </Link>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="w-full flex flex-col items-center">
            <p className="text-xs text-text-muted text-center mb-6 leading-relaxed">
              {t('forgotPasswordPrompt')}
            </p>

            <div className="flex flex-col gap-4 w-full">
              <div className="flex flex-col gap-1.5 text-left">
                <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">{t('emailAddress')}</label>
                <div className="relative">
                  <MdEmail className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-5 h-5" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => {
                      setEmail(e.target.value);
                      setErrorMsg('');
                      setFieldErrors(prev => ({ ...prev, email: '' }));
                    }}
                    placeholder="name@shop.com"
                    className={`w-full pl-11 pr-4 py-3 bg-bg-input border rounded-lg text-text-main placeholder:text-text-muted/40 outline-none text-sm transition-all
                      ${fieldErrors.email ? 'border-color-accent-pink' : 'border-border-subtle focus:border-color-accent-purple'}`}
                  />
                </div>
                {fieldErrors.email && (
                  <span className="text-[11px] text-color-accent-pink font-semibold">{fieldErrors.email}</span>
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
                {loading ? t('syncing') : t('sendResetLink')}
              </button>
            </div>

            <div className="mt-6 text-center">
              <Link
                to="/login"
                className="text-xs font-semibold text-color-accent-purple hover:underline transition-colors"
              >
                ← {t('backToSignIn')}
              </Link>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};

export default ForgotPassword;

