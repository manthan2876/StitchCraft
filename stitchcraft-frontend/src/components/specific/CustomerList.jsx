import React from 'react';
import { MdSearch, MdPersonAdd, MdChevronRight } from 'react-icons/md';

export const CustomerList = ({ customers, selectedCustomerId, onSelectCustomer, onAddCustomerClick, searchQuery, setSearchQuery }) => {
  return (
    <div className="bg-bg-secondary rounded-[20px] border border-border-subtle overflow-hidden shadow-card flex flex-col h-full">
      {/* Header controls */}
      <div className="p-6 border-b border-border-subtle flex flex-col gap-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-bold text-text-main tracking-wide">Client Database</h3>
            <p className="text-xs text-text-muted mt-0.5">Manage customer cards and measurements</p>
          </div>
          <button
            onClick={onAddCustomerClick}
            className="w-9 h-9 rounded-xl bg-color-accent-purple hover:bg-color-accent-purple/90 flex items-center justify-center text-white-forced shadow-lg shadow-color-accent-purple/20 transition-all active:scale-95 cursor-pointer"
            title="Add New Customer"
          >
            <MdPersonAdd className="w-5 h-5 text-white-forced" />
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <input
            type="text"
            placeholder="Search by name or phone..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-bg-input border border-border-subtle text-sm rounded-xl px-4 py-2.5 pl-11 text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple/50 transition-all"
          />
          <MdSearch className="w-5 h-5 text-text-muted absolute left-4 top-1/2 transform -translate-y-1/2" />
        </div>
      </div>

      {/* List content */}
      <div className="flex-1 overflow-y-auto divide-y divide-border-subtle max-h-[500px]">
        {customers.length === 0 ? (
          <div className="p-8 text-center text-sm text-text-muted">
            No customers found. Click the '+' button to add one.
          </div>
        ) : (
          customers.map((cust) => {
            const isSelected = cust.id === selectedCustomerId;
            return (
              <div
                key={cust.id}
                onClick={() => onSelectCustomer(cust)}
                className={`p-4 flex items-center justify-between cursor-pointer transition-all duration-200 hover:bg-bg-hover
                  ${isSelected ? 'bg-color-accent-purple/10 border-l-4 border-color-accent-purple' : 'border-l-4 border-transparent'}`}
              >
                <div className="flex items-center gap-3">
                  {/* Avatar Circle */}
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-sm font-black shadow-md
                    ${isSelected ? 'bg-color-accent-purple text-white-forced' : 'bg-bg-hover text-text-muted'}`}
                  >
                    {cust.name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()}
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-text-main leading-snug">{cust.name}</h4>
                    <span className="text-xs text-text-muted font-medium">{cust.phone}</span>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-md bg-bg-input text-text-muted border border-border-subtle">
                    {cust.ordersCount} Jobs
                  </span>
                  <MdChevronRight className={`w-5 h-5 transition-transform ${isSelected ? 'text-color-accent-purple translate-x-1' : 'text-text-muted'}`} />
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};

export default CustomerList;
