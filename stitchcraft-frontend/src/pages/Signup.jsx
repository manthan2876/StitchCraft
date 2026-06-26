import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { GiScissors, GiPadlock } from 'react-icons/gi';
import { MdEmail, MdPerson, MdStore, MdPhone, MdLocationOn } from 'react-icons/md';

export const Signup = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [shopName, setShopName] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [shake, setShake] = useState(false);
  const { register, loading, user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (user) {
      navigate('/dashboard');
    }
  }, [user, navigate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!name || !email || !password || !shopName) {
      setErrorMsg('Name, Email, Password, and Shop Name are required.');
      return;
    }

    try {
      await register(name, email, password, shopName, phone, address);
      navigate('/dashboard');
    } catch (err) {
      setErrorMsg(err.message);
      setShake(true);
      setTimeout(() => setShake(false), 500);
    }
  };

  return (
    <div className="w-screen min-h-screen bg-bg-primary flex flex-col items-center justify-center p-6 select-none">
      <div
        className={`w-full max-w-[450px] bg-bg-secondary rounded-2xl border border-border-subtle p-8 shadow-theme-md transition-all duration-300 my-4
          ${shake ? 'animate-bounce' : ''}`}
      >
        <form onSubmit={handleSubmit} className="w-full flex flex-col items-center">
          <div className="flex flex-col items-center gap-2 mb-6">
            <div className="w-12 h-12 rounded-xl bg-color-accent-purple flex items-center justify-center text-white shadow-sm">
              <GiScissors className="w-6 h-6 transform -rotate-45" />
            </div>
            <h1 className="text-xl font-bold text-text-main mt-2 tracking-wide">Setup Boutique Shop</h1>
            <p className="text-[10px] text-text-muted font-bold tracking-wider uppercase">Create Masterji Owner Account</p>
          </div>

          <div className="flex flex-col gap-3.5 w-full text-left">
            <div className="flex flex-col gap-1">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Masterji Name *</label>
              <div className="relative">
                <MdPerson className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-4.5 h-4.5" />
                <input
                  type="text"
                  value={name}
                  onChange={(e) => { setName(e.target.value); setErrorMsg(''); }}
                  placeholder="Ramesh Kumar"
                  className="w-full pl-11 pr-4 py-2.5 bg-bg-input border border-border-subtle rounded-lg text-text-main placeholder:text-text-muted/40 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>
            </div>

            <div className="flex flex-col gap-1">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Email Address *</label>
              <div className="relative">
                <MdEmail className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-4.5 h-4.5" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); setErrorMsg(''); }}
                  placeholder="ramesh@tailor.com"
                  className="w-full pl-11 pr-4 py-2.5 bg-bg-input border border-border-subtle rounded-lg text-text-main placeholder:text-text-muted/40 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>
            </div>

            <div className="flex flex-col gap-1">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Secure Password *</label>
              <div className="relative">
                <GiPadlock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-4.5 h-4.5" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); setErrorMsg(''); }}
                  placeholder="Min 4 characters"
                  className="w-full pl-11 pr-4 py-2.5 bg-bg-input border border-border-subtle rounded-lg text-text-main placeholder:text-text-muted/40 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>
            </div>

            <div className="flex flex-col gap-1">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Tailor Shop Name *</label>
              <div className="relative">
                <MdStore className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-4.5 h-4.5" />
                <input
                  type="text"
                  value={shopName}
                  onChange={(e) => { setShopName(e.target.value); setErrorMsg(''); }}
                  placeholder="Ramesh Tailors"
                  className="w-full pl-11 pr-4 py-2.5 bg-bg-input border border-border-subtle rounded-lg text-text-main placeholder:text-text-muted/40 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>
            </div>

            <div className="flex flex-col gap-1">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Shop Phone Number</label>
              <div className="relative">
                <MdPhone className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-4.5 h-4.5" />
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => { setPhone(e.target.value); setErrorMsg(''); }}
                  placeholder="9876543210"
                  className="w-full pl-11 pr-4 py-2.5 bg-bg-input border border-border-subtle rounded-lg text-text-main placeholder:text-text-muted/40 outline-none focus:border-color-accent-purple text-sm transition-all"
                />
              </div>
            </div>

            <div className="flex flex-col gap-1">
              <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider">Shop Location Address</label>
              <div className="relative">
                <MdLocationOn className="absolute left-4 top-1/2 transform -translate-y-1/2 text-text-muted w-4.5 h-4.5" />
                <input
                  type="text"
                  value={address}
                  onChange={(e) => { setAddress(e.target.value); setErrorMsg(''); }}
                  placeholder="12, Gandhi Road, Salem"
                  className="w-full pl-11 pr-4 py-2.5 bg-bg-input border border-border-subtle rounded-lg text-text-main placeholder:text-text-muted/40 outline-none focus:border-color-accent-purple text-sm transition-all"
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
              className="mt-3 w-full py-3 bg-color-accent-purple hover:bg-color-accent-purple-hover text-white font-medium rounded-lg active:scale-98 transition-all duration-200 cursor-pointer disabled:opacity-50 text-sm shadow-sm"
            >
              {loading ? 'Registering Shop...' : 'Create Account & Shop'}
            </button>
          </div>

          <div className="mt-6 text-center">
            <span className="text-[11px] text-text-muted font-semibold tracking-wider">
              Already have a shop account?{' '}
              <Link to="/login" className="text-color-accent-purple font-bold hover:underline">
                Sign In
              </Link>
            </span>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Signup;
