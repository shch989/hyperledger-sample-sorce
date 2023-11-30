# 사용 방법
## 선행 조건
### 기존 네트워크 확인 및 정리
```
# 현재 수행 상황 확인
docker ps -a
docker network ls
docker volume ls
docker images dev-*

# 초기화 명령들
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images dev-* -q)
docker network prune
docker volume prune
```

### Git에서 샘플 파일 불러오기
```
git clone https://github.com/shch989/network
```
### 네트워크 실행
ccp-generate.sh에서 connection-org1.json를 생성할 경로 수정

```
./startnetwork.sh
```
```
./createchannel.sh
```

### 체인코드 실행
```
./network.sh deployCC -ccn <체인코드명> -ccp <체인코드경로> -ccl go
```
### 예시
```
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go/ -ccl go
```

### 네트워크 다운
```
./networkdown.sh
```