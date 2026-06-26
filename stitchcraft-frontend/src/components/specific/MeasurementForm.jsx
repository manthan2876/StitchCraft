import React from 'react';
import InputField from '../common/InputField';
import { useLanguage } from '../../context/LanguageContext';

export const MeasurementForm = ({ apparelType, measurements, onChange }) => {
  const { t } = useLanguage();

  const handleNumChange = (e) => {
    const { name, value } = e.target;
    onChange({
      ...measurements,
      [name]: value === '' ? '' : parseFloat(value) || 0
    });
  };

  const handleTextChange = (e) => {
    const { name, value } = e.target;
    onChange({
      ...measurements,
      [name]: value
    });
  };

  const isBlouseOrLehenga = apparelType === 'Blouse' || apparelType === 'Lehenga';
  const isPantOrSuit = apparelType === 'Pants' || apparelType === 'Suit';

  // Helper with fallbacks for translations
  const tf = (key, fallback) => {
    const val = t(key);
    return val === key ? fallback : val;
  };

  const apparelTypeLabel = apparelType
    ? tf('apparel' + apparelType, apparelType)
    : apparelType;

  // Dynamic length label
  const getLengthLabel = () => {
    if (apparelType === 'Blouse') return tf('blouseLength', 'Blouse Length');
    if (apparelType === 'Pants') return tf('pantsLength', 'Pants Length');
    return tf('totalLength', 'Total Length');
  };

  return (
    <div className="flex flex-col gap-6 w-full">
      <div className="flex items-center justify-between">
        <h4 className="text-sm font-bold text-color-accent-purple uppercase tracking-wider">
          {tf('anatomicalMeasurements', 'Anatomical Measurements')}
        </h4>
        <span className="text-[10px] font-bold text-text-muted px-2 py-0.5 bg-bg-primary rounded border border-border-subtle uppercase">
          {tf('apparelTypeLabel', 'Apparel Type')}: {apparelTypeLabel}
        </span>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        {/* Common Parameters */}
        {apparelType !== 'Pants' && (
          <>
            <InputField
              label={isBlouseOrLehenga ? tf('bust', 'Bust') : tf('chest', 'Chest')}
              name="chest"
              type="number"
              step="0.1"
              value={measurements.chest || ''}
              onChange={handleNumChange}
              placeholder="e.g. 38"
            />
            <InputField
              label={tf('waist', 'Waist')}
              name="waist"
              type="number"
              step="0.1"
              value={measurements.waist || ''}
              onChange={handleNumChange}
              placeholder="e.g. 32"
            />
            <InputField
              label={tf('hips', 'Hips')}
              name="hips"
              type="number"
              step="0.1"
              value={measurements.hips || ''}
              onChange={handleNumChange}
              placeholder="e.g. 40"
            />
            <InputField
              label={tf('shoulderWidth', 'Shoulder Width')}
              name="shoulder"
              type="number"
              step="0.1"
              value={measurements.shoulder || ''}
              onChange={handleNumChange}
              placeholder="e.g. 17"
            />
            <InputField
              label={tf('sleeveLength', 'Sleeve Length')}
              name="sleeves"
              type="number"
              step="0.1"
              value={measurements.sleeves || ''}
              onChange={handleNumChange}
              placeholder="e.g. 24"
            />
          </>
        )}

        {/* Shirt/Suit/Kurta Parameters */}
        {apparelType !== 'Pants' && !isBlouseOrLehenga && (
          <InputField
            label={tf('neck', 'Neck')}
            name="neck"
            type="number"
            step="0.1"
            value={measurements.neck || ''}
            onChange={handleNumChange}
            placeholder="e.g. 16"
          />
        )}

        {/* Blouse Specific Parameters */}
        {apparelType === 'Blouse' && (
          <>
            <InputField
              label={tf('frontNeck', 'Front Neck')}
              name="frontNeck"
              type="number"
              step="0.1"
              value={measurements.frontNeck || ''}
              onChange={handleNumChange}
              placeholder="e.g. 7.5"
            />
            <InputField
              label={tf('backNeck', 'Back Neck')}
              name="backNeck"
              type="number"
              step="0.1"
              value={measurements.backNeck || ''}
              onChange={handleNumChange}
              placeholder="e.g. 9"
            />
          </>
        )}

        {/* Lehenga Specific Parameters */}
        {apparelType === 'Lehenga' && (
          <>
            <InputField
              label={tf('lehengaLength', 'Lehenga Length')}
              name="lehengaLength"
              type="number"
              step="0.1"
              value={measurements.lehengaLength || ''}
              onChange={handleNumChange}
              placeholder="e.g. 40"
            />
            <InputField
              label={tf('choliLength', 'Choli Length')}
              name="choliLength"
              type="number"
              step="0.1"
              value={measurements.choliLength || ''}
              onChange={handleNumChange}
              placeholder="e.g. 14"
            />
          </>
        )}

        {/* Pants Specific Parameters */}
        {isPantOrSuit && (
          <>
            {apparelType === 'Pants' && (
              <>
                <InputField
                  label={tf('waist', 'Waist')}
                  name="waist"
                  type="number"
                  step="0.1"
                  value={measurements.waist || ''}
                  onChange={handleNumChange}
                  placeholder="e.g. 34"
                />
                <InputField
                  label={tf('hips', 'Hips')}
                  name="hips"
                  type="number"
                  step="0.1"
                  value={measurements.hips || ''}
                  onChange={handleNumChange}
                  placeholder="e.g. 40"
                />
              </>
            )}
            <InputField
              label={tf('inseam', 'Inseam')}
              name="inseam"
              type="number"
              step="0.1"
              value={measurements.inseam || ''}
              onChange={handleNumChange}
              placeholder="e.g. 32"
            />
          </>
        )}

        {/* Length parameter */}
        <InputField
          label={getLengthLabel()}
          name="length"
          type="number"
          step="0.1"
          value={measurements.length || ''}
          onChange={handleNumChange}
          placeholder="e.g. 29"
        />
      </div>

      {/* Special Sewing Notes */}
      <div className="flex flex-col gap-2">
        <label className="text-sm font-medium text-text-muted">{tf('specialSewingStyleNotes', 'Special Sewing / Style Notes')}</label>
        <textarea
          name="notes"
          value={measurements.notes || ''}
          onChange={handleTextChange}
          placeholder={tf('specialNotesPlaceholder', 'Write any specific client requests or details here...')}
          className="w-full h-24 px-4 py-3 bg-bg-input border border-border-medium rounded-xl text-text-main placeholder:text-text-muted/50 outline-none focus:border-color-accent-purple transition-all duration-200 resize-none text-sm"
        />
      </div>
    </div>
  );
};

export default MeasurementForm;
