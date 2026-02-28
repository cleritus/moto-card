export interface PaginationParams {
  page: number;
  limit: number;
  skip: number;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

/**
 * Extract pagination parameters from query string
 * Defaults: page=1, limit=20
 */
export const getPaginationParams = (query: { page?: string | string[]; limit?: string | string[] }): PaginationParams => {
  const page = Math.max(1, parseInt(query.page as string) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit as string) || 20)); // Max 100 items per page
  const skip = (page - 1) * limit;

  return { page, limit, skip };
};

/**
 * Build pagination metadata object
 */
export const buildPaginationMeta = (page: number, limit: number, total: number): PaginationMeta => ({
  page,
  limit,
  total,
  totalPages: Math.ceil(total / limit),
});

/**
 * Calculate skip value from page and limit
 */
export const calculateSkip = (page: number, limit: number): number => {
  return (page - 1) * limit;
};