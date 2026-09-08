import pathlib, re

root = pathlib.Path('lib')
count=0
for f in root.rglob('*.dart'):
  text=f.read_text(encoding='utf-8', errors='ignore')
  orig=text
  # Pattern: child: ListTile( or return ListTile( or => ListTile( or standalone ListTile( at start of line
  # We replace with Material wrapper and add extra closing after ListTile's matching )
  # Simple but safe: replace "ListTile(" with "Material(... child: ListTile(" and then find its closing and add extra ")," after it
  # We'll do iterative

  def wrap_listtiles(s):
    out=[]
    i=0
    wrapped=0
    while i < len(s):
      # Look for ListTile( not already inside our wrapper
      m=re.search(r'(?<!Material\(type: MaterialType.transparency, child: )ListTile\s*\(', s[i:])
      if not m:
        out.append(s[i:])
        break
      start = i + m.start()
      out.append(s[i:start])
      # Found ListTile(
      # Count paren depth to find its matching )
      j = start + m.group().index('(')
      depth=0
      k=j
      while k < len(s):
        if s[k]=='(':
          depth+=1
        elif s[k]==')':
          depth-=1
          if depth==0:
            break
        k+=1
      if k>=len(s):
        out.append(s[start:])
        break
      # s[start:k+1] is ListTile(...) including closing )
      listtile_code = s[start:k+1]
      # Wrap it
      wrapped_code = f"Material(type: MaterialType.transparency, child: {listtile_code},)"
      out.append(wrapped_code)
      i = k+1
      wrapped+=1
    return ''.join(out), wrapped

  # Only wrap if inside child: return => or standalone indented ListTile — avoid double wrap already wrapped files from 44954be which had 22 but count 0 suggests not wrapped
  # For safety, wrap all bare ListTile not already preceded by our Material
  if 'ListTile(' in text:
    new_text, w = wrap_listtiles(text)
    if w>0 and new_text!=orig:
      f.write_text(new_text, encoding='utf-8')
      print(f"Wrapped {w} in {f} ")
      count+=w

print(f"TOTAL wrapped: {count}")
