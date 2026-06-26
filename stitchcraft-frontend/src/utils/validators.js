export const validatePhoneNumber = (phone) => {
  const re = /^[6-9]\d{9}$/;
  return re.test(String(phone));
};

export const validateRequired = (val) => {
  if (val === undefined || val === null) return false;
  if (typeof val === 'string') return val.trim().length > 0;
  return true;
};
