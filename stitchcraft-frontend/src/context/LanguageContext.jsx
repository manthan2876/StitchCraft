import React, { createContext, useState, useContext } from 'react';
import { translations } from '../utils/translations';

const LanguageContext = createContext();

export const LanguageProvider = ({ children }) => {
  const [language, setLanguage] = useState(() => {
    const saved = localStorage.getItem('stitchcraft_language');
    return saved === 'gu' || saved === 'hi' ? saved : 'en';
  });

  const changeLanguage = (langCode) => {
    if (langCode === 'en' || langCode === 'gu' || langCode === 'hi') {
      setLanguage(langCode);
      localStorage.setItem('stitchcraft_language', langCode);
    }
  };

  const t = (key) => {
    const langSet = translations[language] || translations['en'];
    return langSet[key] || translations['en'][key] || key;
  };

  return (
    <LanguageContext.Provider value={{ language, changeLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
};
