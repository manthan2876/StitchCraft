/* src/pages/Profile.jsx */
import React from 'react';
import Card from '../components/common/Card';
import { MdEdit, MdLogout } from 'react-icons/md';

// Custom State/Business Logic Hook
import useProfile from '../features/profile/hooks/useProfile';

// Modular Tab Components
import ProfileTab from '../features/profile/components/ProfileTab';
import ShopInfoTab from '../features/profile/components/ShopInfoTab';
import SettingsTab from '../features/profile/components/SettingsTab';
import ChangePasswordTab from '../features/profile/components/ChangePasswordTab';
import DataConflictModal from '../features/profile/components/DataConflictModal';

// Modular Modal Components
import ShopModal from '../features/profile/components/ShopModal';
import DeleteShopModal from '../features/profile/components/DeleteShopModal';
import PrivacyActionConfirmModal from '../features/profile/components/PrivacyActionConfirmModal';
import DeletionReasonModal from '../features/profile/components/DeletionReasonModal';

export const Profile = () => {
  const {
    user,
    language,
    changeLanguage,
    t,
    theme,
    toggleTheme,
    activeTab,
    setActiveTab,
    isEditingProfile,
    setIsEditingProfile,
    avatarUrl,
    passwordForm,
    setPasswordForm,
    passwordError,
    passwordSuccess,
    passwordLoading,
    privacyAction,
    privacyPassword,
    setPrivacyPassword,
    isPrivacyModalOpen,
    setIsPrivacyModalOpen,
    privacyError,
    setPrivacyError,
    privacyLoading,
    isReasonModalOpen,
    setIsReasonModalOpen,
    deletionReason,
    setDeletionReason,
    reasonLoading,
    isConflictModalOpen,
    setIsConflictModalOpen,
    conflictsList,
    resolutions,
    setResolutions,
    settings,
    setSettings,
    shops,
    shopsLoading,
    isShopModalOpen,
    setIsShopModalOpen,
    shopModalMode,
    shopForm,
    setShopForm,
    shopError,
    setShopError,
    shopModalLoading,
    deleteTargetShop,
    setDeleteTargetShop,
    deleteShopLoading,
    deleteShopError,
    handleActionClick,
    handleFileChange,
    performImport,
    handlePrivacyPasswordSubmit,
    handleDeletionReasonSubmit,
    handlePasswordSubmit,
    handleLogout,
    handleAvatarChange,
    handleSwitchShop,
    handleOpenCreateShopModal,
    handleOpenEditShopModal,
    handleShopFormSubmit,
    handleDeleteShopSubmit,
    tabKeys,
    getTabLabel,
  } = useProfile();

  const initials = (user?.name || 'MR')
    .split(' ')
    .map(n => n[0])
    .join('')
    .substring(0, 2)
    .toUpperCase();

  return (
    <div className="flex flex-col gap-6 select-none max-w-3xl mx-auto">

      {/* Profile Hero Card */}
      <Card className="relative overflow-hidden">
        <div className="absolute inset-x-0 top-0 h-24 bg-gradient-to-r from-color-accent-purple/40 via-color-accent-blue/30 to-color-accent-pink/30 blur-sm" />

        <div className="relative flex flex-col sm:flex-row items-center sm:items-end gap-4 pt-10 pb-2">
          <input type="file" id="avatar-upload" accept="image/*" className="hidden" onChange={handleAvatarChange} />
          <div
            onClick={() => document.getElementById('avatar-upload').click()}
            className="w-20 h-20 rounded-2xl border-4 border-[var(--color-bg-primary)] overflow-hidden shadow-2xl shrink-0 bg-gradient-to-br from-color-accent-purple to-color-accent-blue flex items-center justify-center cursor-pointer group relative"
            title="Upload Profile Photo"
          >
            <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 flex flex-col items-center justify-center text-[10px] text-white-forced font-bold transition-opacity z-20">
              <MdEdit className="w-4 h-4 mb-0.5 text-color-accent-purple" />
              <span>Upload</span>
            </div>
            {avatarUrl ? (
              <img
                src={avatarUrl}
                alt="Profile"
                className="w-full h-full object-cover"
                onError={e => { e.target.style.display = 'none'; }}
              />
            ) : (
              <span className="text-white-forced font-black text-2xl select-none">
                {initials}
              </span>
            )}
          </div>

          <div className="flex-1 text-center sm:text-left">
            <h2 className="text-2xl font-black text-text-main">{user?.name || 'Masterji Ramesh'}</h2>
            <p className="text-sm text-text-muted font-semibold mt-0.5">
              <span className="text-color-accent-purple font-bold capitalize">{user?.role?.toLowerCase() === 'owner' ? t('roleOwner') : (user?.role || t('roleOwner'))}</span>
              {' • '}
              <span>{user?.shopName || 'Ramesh Tailors'}</span>
            </p>
            <p className="text-xs text-text-muted mt-1">{user?.email}</p>
          </div>

          <button
            onClick={handleLogout}
            className="flex items-center gap-2 px-4 py-2 bg-rose-500/10 border border-rose-500/20 text-rose-500 rounded-xl text-xs font-bold hover:bg-rose-500/20 transition-all cursor-pointer self-end sm:self-auto"
          >
            <MdLogout className="w-4 h-4" />
            <span>{t('logout')}</span>
          </button>
        </div>
      </Card>

      {/* Tabs */}
      <div className="flex gap-2 bg-bg-secondary border border-border-subtle rounded-2xl p-1.5">
        {tabKeys.map(tabKey => (
          <button
            key={tabKey}
            onClick={() => setActiveTab(tabKey)}
            className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all cursor-pointer ${activeTab === tabKey
              ? 'delivery-active-tab border border-color-accent-purple/30 shadow'
              : 'filter-tab-inactive hover:text-text-main'
              }`}
          >
            {getTabLabel(tabKey)}
          </button>
        ))}
      </div>

      {/* ── PROFILE TAB ── */}
      {activeTab === 'Profile' && (
        <ProfileTab
          user={user}
          isEditingProfile={isEditingProfile}
          setIsEditingProfile={setIsEditingProfile}
          t={t}
          shopsCount={shops.length || 1}
        />
      )}

      {/* ── SHOP INFO TAB ── */}
      {activeTab === 'Shop Info' && (
        <ShopInfoTab
          shops={shops}
          shopsLoading={shopsLoading}
          user={user}
          handleOpenCreateShopModal={handleOpenCreateShopModal}
          handleSwitchShop={handleSwitchShop}
          handleOpenEditShopModal={handleOpenEditShopModal}
          setDeleteTargetShop={setDeleteTargetShop}
          t={t}
        />
      )}

      {/* ── SETTINGS TAB ── */}
      {activeTab === 'Settings' && (
        <SettingsTab
          settings={settings}
          setSettings={setSettings}
          theme={theme}
          toggleTheme={toggleTheme}
          language={language}
          changeLanguage={changeLanguage}
          handleActionClick={handleActionClick}
          t={t}
        />
      )}

      {/* ── CHANGE PASSWORD TAB ── */}
      {activeTab === 'Change Password' && (
        <ChangePasswordTab
          passwordForm={passwordForm}
          setPasswordForm={setPasswordForm}
          passwordError={passwordError}
          passwordSuccess={passwordSuccess}
          passwordLoading={passwordLoading}
          handlePasswordSubmit={handlePasswordSubmit}
          t={t}
        />
      )}

      {/* Create/Edit Shop Modal */}
      <ShopModal
        isOpen={isShopModalOpen}
        onClose={() => setIsShopModalOpen(false)}
        mode={shopModalMode}
        shopForm={shopForm}
        setShopForm={setShopForm}
        shopError={shopError}
        setShopError={setShopError}
        shopModalLoading={shopModalLoading}
        handleShopFormSubmit={handleShopFormSubmit}
        t={t}
      />

      {/* Delete Shop Confirmation Modal */}
      <DeleteShopModal
        deleteTargetShop={deleteTargetShop}
        onClose={() => setDeleteTargetShop(null)}
        deleteShopLoading={deleteShopLoading}
        deleteShopError={deleteShopError}
        handleDeleteShopSubmit={handleDeleteShopSubmit}
        t={t}
      />

      {/* Password Confirmation Modal */}
      <PrivacyActionConfirmModal
        isOpen={isPrivacyModalOpen}
        privacyAction={privacyAction}
        privacyPassword={privacyPassword}
        setPrivacyPassword={setPrivacyPassword}
        privacyError={privacyError}
        setPrivacyError={setPrivacyError}
        privacyLoading={privacyLoading}
        handleFileChange={handleFileChange}
        handlePrivacyPasswordSubmit={handlePrivacyPasswordSubmit}
        onClose={() => setIsPrivacyModalOpen(false)}
        t={t}
      />

      {/* Account Deletion Reason Modal */}
      <DeletionReasonModal
        isOpen={isReasonModalOpen}
        deletionReason={deletionReason}
        setDeletionReason={setDeletionReason}
        reasonLoading={reasonLoading}
        handleDeletionReasonSubmit={handleDeletionReasonSubmit}
        onClose={() => setIsReasonModalOpen(false)}
        t={t}
      />

      {/* Conflict Resolution Modal */}
      <DataConflictModal
        isConflictModalOpen={isConflictModalOpen}
        setIsConflictModalOpen={setIsConflictModalOpen}
        conflictsList={conflictsList}
        resolutions={resolutions}
        setResolutions={setResolutions}
        performImport={performImport}
        reasonLoading={reasonLoading}
        t={t}
      />
    </div>
  );
};

export default Profile;