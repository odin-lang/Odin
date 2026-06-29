### odin-wycheproof - Odin core/crypto tests
#### Yawning Angel (yawning at schwanenlied dot me)

This is a test harness that exercises the [Odin][1] `core/crypto`
library with corpus from [Wycheproof][2].

```
$ odin build . -o:speed
$ ./odin-wycheproof ../wycheproof
```

[1]: https://odin-lang.org
[2]: https://github.com/C2SP/wycheproof
