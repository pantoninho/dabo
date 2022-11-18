import React from 'react';

export const Form = ({ children }) => {
  return <form className="flex flex-col gap-4 py-4 px-2">{children}</form>;
};
export const Input = ({ type, label, name, onChange, value }) => {
  return (
    <div className="flex items-center rounded-lg bg-zinc-800 dark:bg-white">
      <label className="px-4 text-white dark:text-zinc-800" htmlFor={name}>
        {label}
      </label>
      <input
        className="flex-1 rounded-lg border-2 border-zinc-800 bg-white py-2 px-4 focus:outline-none dark:border-white dark:bg-zinc-800"
        id={name}
        type={type}
        name={name}
        onChange={onChange ? (e) => onChange(e.target.value) : null}
        value={value}
      />
    </div>
  );
};
