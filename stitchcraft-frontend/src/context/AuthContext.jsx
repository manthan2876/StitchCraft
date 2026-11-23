import React, { createContext, useEffect, useState } from 'react';
import supabase from '../services/supabase';

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(() => {
    const storedUser = localStorage.getItem('stitchcraft_user');
    if (storedUser) {
      try {
        return JSON.parse(storedUser);
      } catch {
        localStorage.removeItem('stitchcraft_user');
      }
    }
    return null;
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    let active = true;
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!active || !session) return;
      localStorage.setItem('stitchcraft_token', session.access_token);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        if (!session) {
          localStorage.removeItem('stitchcraft_token');
          return;
        }
        localStorage.setItem('stitchcraft_token', session.access_token);
      },
    );

    return () => {
      active = false;
      subscription.unsubscribe();
    };
  }, []);

  const login = async (email, password) => {
    setLoading(true);
    try {
      const API_URL = import.meta.env.VITE_API_URL;
      const res = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email.trim().toLowerCase(), password }),
      });

      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(data.message || 'Invalid email or password');
      }

      if (data.token) {
        localStorage.setItem('stitchcraft_token', data.token);
      }
      setUser(data);
      localStorage.setItem('stitchcraft_user', JSON.stringify(data));
      setLoading(false);
      return data;
    } catch (err) {
      setLoading(false);
      throw err;
    }
  };

  const register = async (name, email, password, shopName, phone, address) => {
    setLoading(true);
    try {
      const API_URL = import.meta.env.VITE_API_URL;
      const res = await fetch(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email: email.trim().toLowerCase(), password, shopName, phone, address }),
      });

      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(data.message || 'Registration failed');
      }

      if (data.requiresVerification) {
        setLoading(false);
        throw new Error(data.message || 'Please verify your email before logging in');
      }

      if (data.token) {
        localStorage.setItem('stitchcraft_token', data.token);
      }
      setUser(data);
      localStorage.setItem('stitchcraft_user', JSON.stringify(data));
      setLoading(false);
      return data;
    } catch (err) {
      setLoading(false);
      throw err;
    }
  };

  const logout = async () => {
    await supabase.auth.signOut();
    setUser(null);
    localStorage.removeItem('stitchcraft_user');
    localStorage.removeItem('stitchcraft_token');
  };

  const forgotPassword = async (email) => {
    setLoading(true);
    try {
      const redirectTo = `${window.location.origin}/reset-password`;
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo,
      });
      if (error) throw error;
      setLoading(false);
      return { success: true };
    } catch (err) {
      setLoading(false);
      throw err;
    }
  };

  const resetPassword = async (newPassword) => {
    setLoading(true);
    try {
      const { data, error } = await supabase.auth.updateUser({
        password: newPassword,
      });
      if (error) throw error;
      setLoading(false);
      return data;
    } catch (err) {
      setLoading(false);
      throw err;
    }
  };

  const updateUser = (updatedData) => {
    setUser(prev => {
      if (!prev) return null;
      const newUser = { ...prev, ...updatedData };
      localStorage.setItem('stitchcraft_user', JSON.stringify(newUser));
      return newUser;
    });
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, register, loading, updateUser, forgotPassword, resetPassword }}>
      {children}
    </AuthContext.Provider>
  );
};
