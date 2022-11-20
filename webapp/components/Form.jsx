import React from 'react';

export const Form = ({ children }) => {
  return (
    <form className="flex-col flex flex-1 gap-4 py-4 px-2">{children}</form>
  );
};

export const Input = ({
  type,
  required,
  min,
  step,
  label,
  name,
  onChange,
  value,
  labelClassName,
}) => {
  return (
    <div className="flex items-center rounded-lg bg-zinc-800 dark:bg-white">
      <label
        className={`px-4 text-white dark:text-zinc-800 ${labelClassName}`}
        htmlFor={name}
      >
        {label}
      </label>
      <input
        className="flex-1 rounded-lg border-2 border-zinc-800 bg-white px-4 py-2 focus:outline-none dark:border-white dark:bg-zinc-800 dark:invalid:bg-red-500"
        id={name}
        required={required}
        min={min}
        step={step}
        type={type}
        name={name}
        onChange={onChange ? (e) => onChange(e.target.value) : null}
        value={value}
      />
    </div>
  );
};
