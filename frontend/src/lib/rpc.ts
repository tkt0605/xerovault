import { supabase } from './supabase'

// supabase.rpc()の{data,error}をthrow-on-errorな戻り値に揃える薄いラッパー
export async function rpc<T>(fn: string, args?: Record<string, unknown>): Promise<T> {
  const { data, error } = await supabase.rpc(fn, args)
  if (error) throw new Error(error.message)
  return data as T
}
