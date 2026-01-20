# git 
## Useful Commands

#### Set user and mail
```
git config user.name "piotex"
git config user.email "pkubon2@gmail.com"
```

#### Change commit author
```
git commit --amend --author="piotex <pkubon2@gmail.com>"
```

#### Show 5 latest commits with their author
```
git log --pretty=format:"%h %an <%ae> %s" | head -n 5
```
