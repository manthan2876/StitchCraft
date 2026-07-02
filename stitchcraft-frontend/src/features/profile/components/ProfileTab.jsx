/* src/features/profile/components/ProfileTab.jsx */
import React from 'react';
import Card from '../../../components/common/Card';
import { MdPerson, MdEmail, MdBusiness, MdSecurity, MdEdit, MdSave } from 'react-icons/md';

export const ProfileTab = ({
  user,
  isEditingProfile,
  setIsEditingProfile,
  t,
  shopsCount,
}) => {
  return (
    <Card className="flex flex-col gap-5">
      <div className="flex items-center justify-between border-b border-border-subtle pb-4">
        <div>
          <h3 className="text-base font-bold text-text-main">{t('personalInfo')}</h3>
          <p className="text-xs text-text-muted mt-0.5">{t('personalInfoSub')}</p>
        </div>
        {!isEditingProfile ? (
          <button
            onClick={() => setIsEditingProfile(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-bg-secondary border border-border-medium rounded-xl text-xs font-bold text-text-muted hover:text-text-main cursor-pointer"
          >
            <MdEdit className="w-4 h-4" />{t('edit')}
          </button>
        ) : (
          <button
            onClick={() => setIsEditingProfile(false)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-color-accent-purple rounded-xl text-xs font-bold text-white-forced cursor-pointer"
          >
            <MdSave className="w-4 h-4 text-white-forced" />{t('save')}
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
        {[
          { label: t('fullName'), value: user?.name || 'Masterji Ramesh', icon: <MdPerson />, key: 'fullName' },
          { label: t('emailAddress'), value: user?.email || 'ramesh@stitchcraft.com', icon: <MdEmail />, key: 'email' },
          { label: t('role'), value: user?.role?.toLowerCase() === 'owner' ? t('roleOwner') : (user?.role || t('roleOwner')), icon: <MdSecurity />, key: 'role' },
          { label: t('shopName'), value: user?.shopName || 'Ramesh Tailors', icon: <MdBusiness />, key: 'shopName' },
        ].map(field => (
          <div key={field.key} className="flex flex-col gap-1.5">
            <label className="text-[10px] font-bold text-text-muted uppercase tracking-wider flex items-center gap-1">
              {React.cloneElement(field.icon, { className: 'w-3.5 h-3.5 text-color-accent-purple' })}
              {field.label}
            </label>
            {isEditingProfile ? (
              <input
                defaultValue={field.value}
                className="px-4 py-2.5 bg-bg-input border border-border-medium rounded-xl text-sm text-text-main outline-none focus:border-color-accent-purple transition-all"
              />
            ) : (
              <p className="px-4 py-2.5 bg-bg-secondary border border-border-subtle rounded-xl text-sm text-text-main font-semibold">
                {field.value}
              </p>
            )}
          </div>
        ))}
      </div>

      <div className="grid grid-cols-3 gap-4 mt-2 border-t border-border-subtle pt-5">
        {[
          { label: t('accountType'), value: user?.role?.toLowerCase() === 'owner' ? t('roleOwner') : (user?.role || t('roleOwner')) },
          { label: t('shopsManaged'), value: String(shopsCount) },
          { label: t('memberSince'), value: '2026' },
        ].map(s => (
          <div key={s.label} className="bg-bg-secondary p-4 rounded-xl border border-border-subtle text-center">
            <p className="text-xl font-black text-text-main">{s.value}</p>
            <p className="text-[10px] text-text-muted font-bold uppercase tracking-wider mt-1">{s.label}</p>
          </div>
        ))}
      </div>
    </Card>
  );
};

export default ProfileTab;
