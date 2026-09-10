# secrets/

CI와 배포에 필요한 자격증명을 두는 곳. 이 디렉터리의 파일은 `README.md` 를 빼고
**git-crypt로 암호화되어** 커밋된다 (패턴은 `/.gitattributes`).

저장소는 public이다. 여기 올라간 파일의 내용은 암호문으로만 공개되지만,
**파일 이름과 크기는 그대로 보인다.** 이름에 정보를 담지 말 것.

## 잠금 해제

새로 clone한 뒤에는 파일이 암호문 그대로다. 키로 풀어야 한다.

```bash
git-crypt unlock ~/.config/git-crypt/car-log.key
git-crypt status -e          # 암호화 대상 파일 목록 확인
```

키 파일은 저장소 밖에 있고 백업 책임은 사용자에게 있다. 키를 잃으면 여기 있는
파일은 복구할 수 없다.

## 새 비밀 파일을 추가할 때

1. `/.gitattributes` 에 패턴이 있는지 먼저 확인한다. 없으면 추가한다.
2. `git add` 후 `git-crypt status -e` 로 그 파일이 암호화 대상인지 확인한다.
3. 확인 전에는 push하지 않는다. 패턴에 없는 파일은 평문으로 올라간다.
