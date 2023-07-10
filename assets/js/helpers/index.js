export { default as categoryColors } from './constants';

export function getYearMonth(dateStr) {
  const date = new Date(dateStr);
  const year = date.getFullYear();
  const month = date.getMonth();
  return `${year}-${month < 9 ? '0' : ''}${month + 1}`;
};
