# Pinned HTML sources from casenote.kr
# Each fetchurl is a fixed-output derivation with sha256 hash.
# Cached by Nix store; with magic-nix-cache-action in CI, no re-fetch needed.
#
# To update a hash after a page changes:
#   nix-prefetch-url --name "<name>.html" --type sha256 "<url>"
{ fetchurl }:

let
  base = "https://casenote.kr/%EB%8C%80%EB%B2%95%EC%9B%90";
  fetch = name: id: hash: fetchurl {
    url = "${base}/${id}";
    sha256 = hash;
    inherit name;
  };
in
{
  "2005다71659" = fetch "2005da71659.html" "2005%EB%8B%A471659"
    "18yas9j420yv1nr4rdb5am0d2zqhp7ls645klcdw83s470fvwdnx";

  "2013다49794" = fetch "2013da49794.html" "2013%EB%8B%A449794"
    "1dziq50n0aci5yfixbyf578mhlrhriip3sfj33nn2jlbn8xykf1l";

  "2019다280375" = fetch "2019da280375.html" "2019%EB%8B%A4280375"
    "05sqd70xqvl8v92p46lkzw0mjci6bgz6dlai113h0345ii2hfsxn";

  "91다32190" = fetch "91da32190.html" "91%EB%8B%A432190"
    "060605pl20s38zmxlid1f5q9x9mih1nhs4jhj1gp3jlid8kdpj7z";

  "93다47745" = fetch "93da47745.html" "93%EB%8B%A447745"
    "1wrrw3yi3sgkv9zq7pn5hxdmira57hw80dpr8m36h486kv6a1q3s";

  "94다12074" = fetch "94da12074.html" "94%EB%8B%A412074"
    "1wdh0rg53kc89rin7zbvvr8b39m0cc9m3d1qzjs50qbfg3mj8qk3";

  "98다60828" = fetch "98da60828.html" "98%EB%8B%A460828"
    "0nhrj50bk7b6zd5jgx6jddccll3shjrybslrqsrzzmb0i1b9nj1z";
}
