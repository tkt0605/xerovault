// navigator.clipboardはセキュアコンテキスト(https、またはlocalhost)でのみ存在する。
// LAN IP経由のhttpアクセスなどでは undefined になり得るため、execCommandへのフォールバックを用意する。
export async function copyToClipboard(text: string): Promise<void> {
  if (navigator.clipboard?.writeText) {
    await navigator.clipboard.writeText(text)
    return
  }

  const textarea = document.createElement('textarea')
  textarea.value = text
  textarea.style.position = 'fixed'
  textarea.style.opacity = '0'
  document.body.appendChild(textarea)
  textarea.focus()
  textarea.select()
  document.execCommand('copy')
  document.body.removeChild(textarea)
}
