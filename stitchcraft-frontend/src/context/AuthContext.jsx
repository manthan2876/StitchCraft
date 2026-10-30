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
      // 1. Authenticate with Supabase Auth
      const { data: sbData, error: sbError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (sbError) throw sbError;
      const token = sbData.session.access_token;

      // Provision/fetch the application profile through the backend.
      const API_URL = import.meta.env.VITE_API_URL;
      const res = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || 'Verification with backend failed.');
      }

      const data = await res.json();
      setUser(data);
      localStorage.setItem('stitchcraft_user', JSON.stringify(data));
      localStorage.setItem('stitchcraft_token', token);
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
      // 1. Register with Supabase Auth
      const { data: sbData, error: sbError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { name, shopName, phone, address }
        }
      });

      if (sbError) throw sbError;
      const token = sbData.session?.access_token;

      if (!token) {
        throw new Error('Please check your email to verify your account before logging in.');
      }

      // Provision profile details through the backend.
      const API_URL = import.meta.env.VITE_API_URL;
      const res = await fetch(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ name, email, shopName, phone, address })
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || 'Registration failed.');
      }

      const data = await res.json();
      setUser(data);
      localStorage.setItem('stitchcraft_user', JSON.stringify(data));
      localStorage.setItem('stitchcraft_token', token);
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

  const updateUser = (updatedData) => {
    setUser(prev => {
      if (!prev) return null;
      const newUser = { ...prev, ...updatedData };
      localStorage.setItem('stitchcraft_user', JSON.stringify(newUser));
      return newUser;
    });
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, register, loading, updateUser }}>
      {children}
    </AuthContext.Provider>
  );
};
