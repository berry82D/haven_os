import pathlib, re

root = pathlib.Path('lib/features/kitchen')
count=0
for f in root.rglob('*.dart'):
  text=f.read_text(encoding='utf-8', errors='ignore')
  orig=text
  def wrap(s):
    out=[]; i=0; wrapped=0
    while i < len(s):
      m=re.search(r'(?<!\w)ListTile\s*\(', s[i:])
      if not m:
        out.append(s[i:]); break
      start=i+m.start()
      pre=s[max(0,start-20):start]
      # Skip if preceded by Checkbox, Switch, Radio, or already wrapped
      if 'Checkbox' in pre or 'Switch' in pre or 'Radio' in pre or 'Material(type:' in s[max(0,start-60):start]:
        out.append(s[i:start+8]); i=start+8; continue
      out.append(s[i:start])
      j=start+m.group().find('(')
      depth=0; k=j
      while k < len(s):
        if s[k]=='(': depth+=1
        elif s[k]==')':
          depth-=1
          if depth==0: break
        k+=1
      if k>=len(s): out.append(s[start:]); break
      code=s[start:k+1]
      out.append(f"Material(type: MaterialType.transparency, child: {code},)")
      i=k+1; wrapped+=1
    return ''.join(out), wrapped
  if 'ListTile(' in text:
    new,w=wrap(text)
    if w>0 and new!=orig:
      f.write_text(new,encoding='utf-8'); print(f"Wrapped {w} in {f}"); count+=w
print(f"TOTAL kitchen wrapped: {count}")
