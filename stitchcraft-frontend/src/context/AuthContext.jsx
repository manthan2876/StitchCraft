import React, { createContext, useState } from 'react';

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

  const login = async (email, password) => {
    setLoading(true);
    try {
      const API_URL = import.meta.env.VITE_API_URL;
      const res = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || 'Invalid email or password.');
      }

      const data = await res.json();
      setUser(data);
      localStorage.setItem('stitchcraft_user', JSON.stringify(data));
      localStorage.setItem('stitchcraft_token', data.token);
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
        body: JSON.stringify({ name, email, password, shopName, phone, address })
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.message || 'Registration failed.');
      }

      const data = await res.json();
      setUser(data);
      localStorage.setItem('stitchcraft_user', JSON.stringify(data));
      localStorage.setItem('stitchcraft_token', data.token);
      setLoading(false);
      return data;
    } catch (err) {
      setLoading(false);
      throw err;
    }
  };

  const logout = () => {
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
