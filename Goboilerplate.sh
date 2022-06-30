#!/bin/bash/sh -e

###git installation
git=$(git --version)
if [ -z "$git" ];
then 
echo "git is not installed..."
echo "Installing git..."
apt-get update
apt-get install git
echo "Enter your user.name for git config..."
read username
git config --global user.name "$username"
echo "Enter your user.email for git config..."
read email
git config --global user.email "$email"
# echo "Generating ssh keys..."
# ssh-keygen -o -f $HOME'/.ssh/rsa'
# echo -e " \nThis is your ssh key please copy it...\n"
# cat $HOME'/.ssh/rsa.pub'
# echo -e "\nPlease paste the generated ssh keys here and save the key at the following url..."
# echo "https://gitlab.com/-/profile/keys"
# echo "Have you pasted your ssh key to gitlab press y/n for [Yes/No]"
# read answer

# Colors definition
echo '
parse_git_branch() {
     git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \(.*\)/(\1)/"
}
export PS1="\e[1;32m\u\e[1;32m@\e[1;32m\h\e[1;37m:\[\e[94m\]\w \[\e[31m\]\$(parse_git_branch)\[\e[00m\]$ "' >> ~/.bashrc
source ~/.bashrc
echo "git installed..."
else
echo "git is already installed..."
fi

###Golang installation
goenv=$(go env)
# ERROR=$(<go env)
home=$HOME
 
if hash $goenv 2>/dev/null;
then
    echo "golang not installed"
    echo "installing golang ..."
	echo "Please provide the golang version which you want to install in format of x.xx.x and latest version is 1.17.8"
	read goversion
    wget https://golang.org/dl/go$goversion.linux-amd64.tar.gz
    tar -C $home -xzf go$goversion.linux-amd64.tar.gz
    echo 'export PATH=$PATH:$home/go/bin' >> ~/.bashrc
	source ~/.bashrc
	
else 
echo "Golang is already installed..." 
for env in $goenv
do
case $env in

  *"GOPATH="*)
    gopath=$env
    ;;
esac
done

if [ -z $gopath ]
then
    echo "golang environment variable not set"
    echo "environment setup in progress"
   echo '
    export GOPATH=$HOME/go
    export PATH=$PATH:$home/go/bin' >> ~/.bashrc
	source ~/.bashrc
	
 else
 echo "GOPATH is already set..."   
fi
fi
##Golang installation done

##Mysql installation
mysql=$(mysql --version)
if [ -z "$mysql" ];
then 
echo "Mysql is not installed...."
echo "Installing mysql..."
apt update
apt upgrade
apt install mysql-server
mysql --version
mysql_secure_installation
service mysql start
else "Mysql is already installed...."
fi

##Mysql installation done...

#Project setup start...
#go to GOPATH
for env in $goenv
do
case $env in

  *"GOPATH="*)
    gopath=$env
    ;;
esac
done
IFS='"' #setting comma as delimiter  
read -a strarr <<<"$gopath" #reading str as an array as tokens separated by IFS  
domain=${strarr[1]}
cd $domain
echo "Do you want to create project or module..."
echo "1. New Project"
echo "2. Add Module"
echo "Press 1 for new project and 2 for adding new module."
read input

if [ $input = "1" ]
then
#cloning the repository from gitlab
git clone https://gitlab.com/abhishek.k8/crud.git
FILE=crud
if [ ! -d "$FILE" ]; then
echo "Repository is not found.."
exit
fi

#Reading git username and email...
#echo "Enter your user.name for git config..."
username=$(git config --global user.name)
email=$(git config --global user.email)
#git config --global user.name "$username"
#echo "Enter your user.email for git config..."
#read email
#git config --global user.email "$email"


#Reading project name...
echo "Enter the name of folder for your project..."
read projectname
lowercaseprojectname=`echo $projectname  | tr '[A-Z]' '[a-z]'`
FILE=crud
if [ -d "$FILE" ]; then
mv crud $lowercaseprojectname
else 
echo "Repository is not found"
exit
fi
cd $lowercaseprojectname
echo "Please enter the git repository https url example:https://gitlab.com/$username/$projectname.git"
read giturl  
git remote set-url origin $giturl
IFS='//' #setting comma as delimiter  
read -a strarr <<<"$giturl" #reading str as an array as tokens separated by IFS  
domain=${strarr[2]}
name=${strarr[3]}
# echo "Please enter the new branch name except main/master..."
# read branchname
# git checkout -b $branchname
cd src
# touch main.go
echo 'package main

import (
	"strings"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"'$domain'/'$name'/'$lowercaseprojectname'/src/config"
	"'$domain'/'$name'/'$lowercaseprojectname'/src/cron"

	"'$domain'/'$name'/'$lowercaseprojectname'/src/database"
	"'$domain'/'$name'/'$lowercaseprojectname'/src/migration"
	route "'$domain'/'$name'/'$lowercaseprojectname'/src/routes"
)

var router *gin.Engine

func main() {
	//initialize application with toml file
	if err := config.Init(); err != nil {
		log.Error(err)
	}
	// router = gin.Default()
	router = gin.New()
	if strings.ToLower(config.AppConfig.Environment) == "development" {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}

	router.Use(CORSMiddleware())
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	mainRouter := new(route.MainRouter)
	appVer := "api/v1"
	mainRouter.GetRoutes(router.Group(appVer))
	//start the databse
	dbconn := database.ConnectSQL()
	defer dbconn.Close()
	migration.Migrate()

	//initialting cron
	var cron = cron.Cron{}
	cron.Init()

	//server starting log
	log.Info("Server starting at :: ", config.AppConfig.Server.Host+":"+config.AppConfig.Server.Port)

	router.Run(":" + config.AppConfig.Server.Port)
}

//CORSMiddleware -
func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// c.BindHeader()
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Credentials", "true")
		// c.Header("Content-Length", "402653184")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, authorization,Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Header("Access-Control-Allow-Methods", "POST , HEAD , PATCH , OPTIONS, GET, PUT, DELETE")

		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		// c.Writer.Header().Set("Content-Length", "402653184")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token,authorization, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST , HEAD, PATCH , OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}' > main.go

#Reading controller filename
echo "Please enter the folder name under controller folder..."
read packagename
lowercasepackagename=`echo $packagename  | tr '[A-Z]' '[a-z]'`
cd controller
mv user $lowercasepackagename
cd $lowercasepackagename
mv user.go $lowercasepackagename.go
# cd $lowercasepackagename.go

#Reading the file name under controller
# mv user.go $lowercasepackagename.go
controllername=`echo $packagename | sed -r 's/(^|_)([a-z])/\U\2/g'`
echo 'package '$lowercasepackagename'

import (
	// "middlewares"

	"fmt"
	"net/http"
	"strconv"

	"github.com/asaskevich/govalidator"
	"github.com/gin-gonic/gin"

	"'$domain'/'$name'/'$lowercaseprojectname'/src/model"
	res "'$domain'/'$name'/'$lowercaseprojectname'/src/response"
)

//GetRoutes -
func (uc *'$controllername'Controller) GetRoutes(appGroup *gin.RouterGroup) {

	appGroup.POST("/register", uc.create'$controllername')
	appGroup.PUT("/update", uc.update'$controllername')
	appGroup.DELETE("/delete", uc.delete'$controllername')
	appGroup.GET("/get'$controllername'", uc.get'$controllername')
	appGroup.GET("/getAll'$controllername'", uc.getAll'$controllername')

}

func (uc *'$controllername'Controller) create'$controllername'(c *gin.Context) {
	var '$lowercasepackagename' model.'$controllername'
	c.Bind(&'$lowercasepackagename')
	_, err := govalidator.ValidateStruct('$lowercasepackagename')
	if err != nil {
		c.JSON(http.StatusPreconditionFailed, res.PreConditionFailed(c, err))
		return
	}
	err = '$lowercasepackagename'.Register()
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusInternalServerError, res.BadDataRequest(c, err))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, '$lowercasepackagename'))
	return

}

func (uc *'$controllername'Controller) update'$controllername'(c *gin.Context) {
	var '$lowercasepackagename' model.Update
	c.Bind(&'$lowercasepackagename')
	var u model.'$controllername'
	val, err := u.Update'$lowercasepackagename'('$lowercasepackagename')
	if err != nil {
		c.JSON(http.StatusInternalServerError, res.InternalServerError(c, res.CustomError("Internal server error")))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, val))
	return

}

func (uc *'$controllername'Controller) delete'$controllername'(c *gin.Context) {
	'$lowercasepackagename'Id, _ := strconv.Atoi(c.Query("'$lowercasepackagename'_id"))
	if '$lowercasepackagename'Id == 0 {
		c.JSON(http.StatusBadRequest, res.CustomError("'$lowercasepackagename' id can not be zero."))
	}
	var '$lowercasepackagename' model.'$controllername'
	err := '$lowercasepackagename'.Delete'$controllername'(uint('$lowercasepackagename'Id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, res.InternalServerError(c, res.CustomError("Internal server error")))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, '$lowercasepackagename'))
	return

}

func (uc *'$controllername'Controller) get'$controllername'(c *gin.Context) {
	'$lowercasepackagename'Id, _ := strconv.Atoi(c.Query("'$lowercasepackagename'_id"))
	if '$lowercasepackagename'Id == 0 {
		c.JSON(http.StatusBadRequest, res.CustomError("'$lowercasepackagename' id can not be zero."))
	}
	var '$lowercasepackagename' model.'$controllername'
	err := '$lowercasepackagename'.Get'$controllername'(uint('$lowercasepackagename'Id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, res.InternalServerError(c, res.CustomError("Internal server error")))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, '$lowercasepackagename'))
	return

}

func (uc *'$controllername'Controller) getAll'$controllername'(c *gin.Context) {
	var '$lowercasepackagename' model.'$controllername'
	err := '$lowercasepackagename'.GetAll'$controllername'()
	if err == nil {
		c.JSON(http.StatusInternalServerError, res.InternalServerError(c, res.CustomError("Internal server error")))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, err))
	return

}' > $lowercasepackagename.go
#Creating struct file...
mv userTypes.go $lowercasepackagename'Types'.go

echo 'package '$lowercasepackagename'

type (
	'$controllername'Controller struct{}
)' > $lowercasepackagename'Types'.go
cd ../..
cd routes

echo 'package route

import (
	"github.com/gin-gonic/gin"
	'$lowercasepackagename' "'$domain'/'$name'/'$lowercasepackagename'/src/controller/'$lowercasepackagename'"
)

type (
	//IRouter default router
	IRouter interface {
		GetRoutes(appGroup *gin.RouterGroup)
		// InitSubRoutes(appGroup *gin.RouterGroup)
	}
	//MainRouter default MainRouter
	MainRouter struct{}
)

//GetRoutes -
func (mc *MainRouter) GetRoutes(appGroup *gin.RouterGroup) {
	mc.InitSubRoutes(appGroup)
}

//InitSubRoutes -
func (mc *MainRouter) InitSubRoutes(appGroup *gin.RouterGroup) {
	controllerMap := makeControllerMap()
	for key, cntrlr := range controllerMap {
		cntrlr.GetRoutes(appGroup.Group(key))
	}
}

func makeControllerMap() map[string]IRouter {
	controllerMap := make(map[string]IRouter)
    controllerMap["'$lowercasepackagename'"] = &'$lowercasepackagename'.'$controllername'Controller{}
	return controllerMap
}
'> router.go
cd ..
cd database
echo 'package database

import (
	"fmt"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql" //You could import dialect
	configs "'$domain'/'$name'/'$lowercaseprojectname'/src/config"

	log "github.com/sirupsen/logrus"
)

var db *gorm.DB

//ConnectSQL - connect to sql server
func ConnectSQL() *gorm.DB {

	var err error

	var mysqlHost = fmt.Sprint(configs.AppConfig.Database.User, ":", configs.AppConfig.Database.Password, "@(", configs.AppConfig.Database.Host, ")/", configs.AppConfig.Database.Name, "?parseTime=true")
	// log.Info(mysqlHost)
	db, err = gorm.Open("mysql", mysqlHost)

	// if there is an error opening the connection, handle it
	if err != nil {
		log.Panic(err.Error())
	}

	//set limit
	//db.DB().SetConnMaxLifetime(5 * time.Minute)
	db.DB().SetMaxIdleConns(10)
	db.DB().SetMaxOpenConns(40)

	return db
}

//GetSharedConnection return the database connection
func GetSharedConnection() *gorm.DB {
	return db
}' > mysql.go
cd ..
cd cron
echo 'package cron

import (
	"'$domain'/'$name'/'$lowercaseprojectname'/src/config"
)

//Cron struct
type Cron struct{}

//Init - init Cron job
func (ct *Cron) Init() {
	if config.AppConfig.Environment == "Development" {
		return
	}

}' > cron.go
cd ..
path=$PWD
cd config
echo 'package config

import (
	"github.com/BurntSushi/toml"
	log "github.com/sirupsen/logrus"
)

//Config - config for application
type Config struct {}

// AppConfig is the configs for the whole application
var AppConfig *Config

//Init - initialize config
func Init() error {
	if _, err := toml.DecodeFile("'$path'/'$lowercaseprojectname'/config-sample.toml", &AppConfig); err != nil {
		log.Println(" %s", err)
		return err
	}

	return nil
}' > config.go
cd ..
cd model
mv user.go $lowercasepackagename.go
echo 'package model

import (
	"'$domain'/'$name'/'$lowercaseprojectname'/src/database"
)

type (

	'$controllername' struct {
		ID             uint   `gorm:"primary_key" json:"id,omitempty"`
		FirstName      string `gorm:"type:varchar(100);" json:"first_name" valid:"required,length(3|100)"`
		LastName       string `gorm:"type:varchar(100);" json:"last_name" valid:"required,length(1|100)"`
		Email          string `gorm:"type:varchar(100);unique_index; not null" json:"email" valid:"email,required"`
		Phone          string `gorm:"type:varchar(100);unique_index; not null" json:"phone" valid:"required,length(5|15)"`
		ProfilePicture string `gorm:"type:varchar(100);default:''" json:"profile_picture"`
		Password       string `json:"password,omitempty"`
		Country        string `gorm:"type:varchar(100);default:''" json:"country" valid:"required,length(1|100)"`
		State          string `gorm:"type:varchar(100);default:''" json:"state" valid:"required,length(2|100)"`
		Address        string `gorm:"type:varchar(255);default:''" json:"address" valid:"required,length(3|255)"`
		ZipCode        string `gorm:"type:varchar(12);default:''" json:"zip_code" valid:"required,length(3|10)"`
	}
	//ReferralInfo struct
	Update struct {
		ID             uint   `gorm:"primary_key" json:"id,omitempty" `
		FirstName      string `gorm:"type:varchar(100);" json:"first_name"`
		LastName       string `gorm:"type:varchar(100);" json:"last_name"`
		ProfilePicture string `gorm:"type:varchar(100);default:''" json:"profile_picture"`
		Password       string `json:"password,omitempty"`
		Country        string `gorm:"type:varchar(100);default:''" json:"country"`
		State          string `gorm:"type:varchar(100);default:''" json:"state" `
		Address        string `gorm:"type:varchar(255);default:''" json:"address"`
		ZipCode        string `gorm:"type:varchar(12);default:''" json:"zip_code"`
	}
)

//Register register a '$lowercasepackagename'
func (u *'$controllername') Register() error {
	//database connection
	dbconn := database.GetSharedConnection()
	tx := dbconn.Begin()
	if err := tx.Create(u).Error; err != nil {

		//log error and return
		// log.Error(u)
		tx.Rollback()
		return err
	}

	if err := tx.Commit().Error; err != nil {
		return err
	}
	return nil
}

//Get'$controllername'
func (u *'$controllername') Get'$controllername'('$lowercasepackagename'ID uint) error {
	//database connection
	dbconn := database.GetSharedConnection()
	if err := dbconn.Debug().Select(`id,first_name,last_name,email,phone,profile_picture,country,state,address,zip_code`).
		Where(`id=?`, '$lowercasepackagename'ID).First(&u).Error; err != nil {
		return err
	}
	return nil
}

func (u *'$controllername') GetAll'$controllername'() []'$controllername' {
	var (
		'$lowercasepackagename's []'$controllername'
	)
	db := database.GetSharedConnection()
	query := db.Debug().Select(`
			first_name,
			last_name,
			email,
			phone,
			profile_picture,
			password,
			country,
			state,
			address,
			zip_code
	`).Table("'$lowercasepackagename's")
	query.Scan(&'$lowercasepackagename's)
	return '$lowercasepackagename's
}

func (u *'$controllername') Update'$lowercasepackagename'('$lowercasepackagename' Update) (*'$controllername', error) {
	dbconn := database.GetSharedConnection()
	if err := dbconn.Debug().Where(`id=?`, '$lowercasepackagename'.ID).Find(&u).Updates(map[string]interface{}{
		"first_name":      '$lowercasepackagename'.FirstName,
		"last_name":       '$lowercasepackagename'.LastName,
		"profile_picture": '$lowercasepackagename'.ProfilePicture,
		"password":        '$lowercasepackagename'.Password,
		"country":         '$lowercasepackagename'.Country,
		"state":           '$lowercasepackagename'.State,
		"address":         '$lowercasepackagename'.Address,
		"zip_code":        '$lowercasepackagename'.ZipCode,
	}).Error; err != nil {
		return nil, err
	}
	return u, nil
}

//delete '$lowercasepackagename'
func (u *'$controllername') Delete'$controllername'('$lowercasepackagename'ID uint) error {
	//database connection
	dbconn := database.GetSharedConnection()
	if err := dbconn.Debug().Where(`id=?`, '$lowercasepackagename'ID).First(&u).Delete(&u).Error; err != nil {
		return err
	}
	return nil
}
' > $lowercasepackagename.go
cd ..
cd migration
echo 'package migration

import (
	"'$domain'/'$name'/'$lowercaseprojectname'/src/database"
	"'$domain'/'$name'/'$lowercaseprojectname'/src/model"
)

//Migrate to migrate the models
func Migrate() {
	dbconn := database.GetSharedConnection()
	//DB migration
	dbconn.Debug().AutoMigrate(&model.'$controllername'{})
}' > migration.go
sed -i '/DB migration/a \dbconn.Debug().AutoMigrate(&model.'$controllername'{})' migration.go

cd ../..    
rm -rf go.mod
rm -rf go.sum
#get the mo module package name.
go mod init $domain'/'$name'/'$lowercaseprojectname
go mod tidy
git add .
git commit -m "First commit..."
echo "Enter your username and password to upload on git..."
branch=$(git branch | sed -nr 's/\*\s(.*)/\1/p')
git push origin $branch
echo "Folder created successfully..."
exec bash


#------------------------------------------------------------Module part---------------------------------------------------------------------------#
else
#New module creation part

# Go to folder path
echo "Please enter the path of the folder of your project example: /home/ubuntu/<name of your project folder>"
read folderpath
cd $folderpath
echo "Please enter module name.."
read modulename
lowercasemodulename=`echo $modulename | tr '[A-Z]' '[a-z]'`
controllername=`echo $modulename | sed -r 's/(^|_)([a-z])/\U\2/g'`
cd src
echo "Please enter the go mod module path example:gitlab.com/<your username>/<your project name>"
read gomodpath  
IFS='/' #setting comma as delimiter  
read -a strarr <<<"$gomodpath" #reading str as an array as tokens separated by IFS  
domain=${strarr[0]}
name=${strarr[1]}
projectname=${strarr[2]}
path=$PWD
cd controller
mkdir $lowercasemodulename
cd $lowercasemodulename
touch $lowercasemodulename.go
echo 'package '$lowercasemodulename'

import (
	// "middlewares"

	"fmt"
	"net/http"
	"strconv"

	"github.com/asaskevich/govalidator"
	"github.com/gin-gonic/gin"

	"'$domain'/'$name'/'$projectname'/src/model"
	res "'$domain'/'$name'/'$projectname'/src/response"
)

//GetRoutes -
func (uc *'$controllername'Controller) GetRoutes(appGroup *gin.RouterGroup) {

	appGroup.POST("/register", uc.create'$controllername')
	appGroup.PUT("/update", uc.update'$controllername')
	appGroup.DELETE("/delete", uc.delete'$controllername')
	appGroup.GET("/get'$controllername'", uc.get'$controllername')
	appGroup.GET("/getAll'$controllername'", uc.getAll'$controllername')

}

func (uc *'$controllername'Controller) create'$controllername'(c *gin.Context) {
	var '$lowercasemodulename' model.'$controllername'
	c.Bind(&'$lowercasemodulename')
	_, err := govalidator.ValidateStruct('$lowercasemodulename')
	if err != nil {
		c.JSON(http.StatusPreconditionFailed, res.PreConditionFailed(c, err))
		return
	}
	err = '$lowercasemodulename'.Register()
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusInternalServerError, res.BadDataRequest(c, err))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, '$lowercasemodulename'))
	return

}

func (uc *'$controllername'Controller) update'$controllername'(c *gin.Context) {
	var '$lowercasemodulename' model.Update
	c.Bind(&'$lowercasemodulename')
	var u model.'$controllername'
	val, err := u.Update'$lowercasemodulename'('$lowercasemodulename')
	if err != nil {
		c.JSON(http.StatusInternalServerError, res.InternalServerError(c, res.CustomError("Internal server error")))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, val))
	return

}

func (uc *'$controllername'Controller) delete'$controllername'(c *gin.Context) {
	'$lowercasemodulename'Id, _ := strconv.Atoi(c.Query("'$lowercasemodulename'_id"))
	if '$lowercasemodulename'Id == 0 {
		c.JSON(http.StatusBadRequest, res.CustomError("'$lowercasemodulename' id can not be zero."))
	}
	var '$lowercasemodulename' model.'$controllername'
	err := '$lowercasemodulename'.Delete'$controllername'(uint('$lowercasemodulename'Id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, res.InternalServerError(c, res.CustomError("Internal server error")))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, '$lowercasemodulename'))
	return

}

func (uc *'$controllername'Controller) get'$controllername'(c *gin.Context) {
	'$lowercasemodulename'Id, _ := strconv.Atoi(c.Query("'$lowercasemodulename'_id"))
	if '$lowercasemodulename'Id == 0 {
		c.JSON(http.StatusBadRequest, res.CustomError("'$lowercasemodulename' id can not be zero."))
	}
	var '$lowercasemodulename' model.'$controllername'
	err := '$lowercasemodulename'.Get'$controllername'(uint('$lowercasemodulename'Id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, res.InternalServerError(c, res.CustomError("Internal server error")))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, '$lowercasemodulename'))
	return

}

func (uc *'$controllername'Controller) getAll'$controllername'(c *gin.Context) {
	var '$lowercasemodulename' model.'$controllername'
	err := '$lowercasemodulename'.GetAll'$controllername'()
	if err == nil {
		c.JSON(http.StatusInternalServerError, res.InternalServerError(c, res.CustomError("Internal server error")))
		return
	}
	c.JSON(http.StatusCreated, res.SuccessResponse(c, err))
	return

}' > $lowercasemodulename.go
touch $lowercasemodulename'Types'.go
echo 'package '$lowercasemodulename'

type (

	'$controllername'Controller struct{}
)
' > $lowercasemodulename'Types'.go
cd ../..
cd model
touch $lowercasemodulename.go
echo 'package model

import (
	"'$domain'/'$name'/'$projectname'/src/database"
)

type (

	'$controllername' struct {
		ID             uint   `gorm:"primary_key" json:"id,omitempty" `
		FirstName      string `gorm:"type:varchar(100);" json:"first_name" valid:"required,length(3|100)"`
		LastName       string `gorm:"type:varchar(100);" json:"last_name" valid:"required,length(1|100)"`
		Email          string `gorm:"type:varchar(100);unique_index; not null" json:"email" valid:"email,required"`
		Phone          string `gorm:"type:varchar(100);unique_index; not null" json:"phone" valid:"required,length(5|15)"`
		ProfilePicture string `gorm:"type:varchar(100);default:''" json:"profile_picture"`
		Password       string `json:"password,omitempty"`
		Country        string `gorm:"type:varchar(100);default:''" json:"country" valid:"required,length(1|100)"`
		State          string `gorm:"type:varchar(100);default:''" json:"state" valid:"required,length(2|100)"`
		Address        string `gorm:"type:varchar(255);default:''" json:"address" valid:"required,length(3|255)"`
		ZipCode        string `gorm:"type:varchar(12);default:''" json:"zip_code" valid:"required,length(3|10)"`
	}
)

//Register register a '$lowercasemodulename'
func (u *'$controllername') Register() error {
	//database connection
	dbconn := database.GetSharedConnection()
	tx := dbconn.Begin()
	if err := tx.Create(u).Error; err != nil {

		//log error and return
		// log.Error(u)
		tx.Rollback()
		return err
	}

	if err := tx.Commit().Error; err != nil {
		return err
	}
	return nil
}

//Get'$controllername'
func (u *'$controllername') Get'$controllername'('$lowercasemodulename'ID uint) error {
	//database connection
	dbconn := database.GetSharedConnection()
	if err := dbconn.Debug().Select(`id,first_name,last_name,email,phone,profile_picture,country,state,address,zip_code`).
		Where(`id=?`, '$lowercasemodulename'ID).First(&u).Error; err != nil {
		return err
	}
	return nil
}

func (u *'$controllername') GetAll'$controllername'() []'$controllername' {
	var (
		'$lowercasemodulename's []'$controllername'
	)
	db := database.GetSharedConnection()
	query := db.Debug().Select(`
			first_name,
			last_name,
			email,
			phone,
			profile_picture,
			password,
			country,
			state,
			address,
			zip_code
	`).Table("'$lowercasemodulename's")
	query.Scan(&'$lowercasemodulename's)
	return '$lowercasemodulename's
}

func (u *'$controllername') Update'$lowercasemodulename'('$lowercasemodulename' Update) (*'$controllername', error) {
	dbconn := database.GetSharedConnection()
	if err := dbconn.Debug().Where(`id=?`, '$lowercasemodulename'.ID).Find(&u).Updates(map[string]interface{}{
		"first_name":      '$lowercasemodulename'.FirstName,
		"last_name":       '$lowercasemodulename'.LastName,
		"profile_picture": '$lowercasemodulename'.ProfilePicture,
		"password":        '$lowercasemodulename'.Password,
		"country":         '$lowercasemodulename'.Country,
		"state":           '$lowercasemodulename'.State,
		"address":         '$lowercasemodulename'.Address,
		"zip_code":        '$lowercasemodulename'.ZipCode,
	}).Error; err != nil {
		return nil, err
	}
	return u, nil
}

//delete '$lowercasemodulename'
func (u *'$controllername') Delete'$controllername'('$lowercasemodulename'ID uint) error {
	//database connection
	dbconn := database.GetSharedConnection()
	if err := dbconn.Debug().Where(`id=?`, '$lowercasemodulename'ID).First(&u).Delete(&u).Error; err != nil {
		return err
	}
	return nil
}
' > $lowercasemodulename.go
cd ..
cd routes
sed -i '/github.com/a "'$domain'/'$name'/'$projectname'/src/controller/'$lowercasemodulename'"' router.go
sed -i '/return controllerMap/i \controllerMap["'$lowercasemodulename'"] = &'$lowercasemodulename'.'$controllername'Controller{}' router.go
cd ..
cd migration
sed -i '/DB migration/a \dbconn.Debug().AutoMigrate(&model.'$controllername'{})' migration.go
cd ../..   
echo "Module created successfully..."
fi
