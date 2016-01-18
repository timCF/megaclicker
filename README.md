# Megaclicker

This awesome console util is just for testing web applications. It do only one thing - open webpages and randomly clicks required area. Requirements:

- Linux or Mac OS
- Google Chrome browser and Chrome Driver
- Swith off your tile manager (i3, xmonad, amethyst etc)

For example, how to install Google Chrome and Chrome Driver on debian:

```
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
sudo apt-get update
sudo apt-get install google-chrome-stable

sudo apt-get install unzip
wget http://chromedriver.storage.googleapis.com/2.9/chromedriver_linux64.zip
unzip ./chromedriver_linux64.zip
chmod +x ./chromedriver
sudo mv -f ./chromedriver /usr/local/share/chromedriver
sudo ln -s /usr/local/share/chromedriver /usr/local/bin/chromedriver
sudo ln -s /usr/local/share/chromedriver /usr/bin/chromedriver
```

There are binary releases for Linux and Mac, you can run them like this:

```
./start.sh --url https://ya.ru --x-res 1024 --x-from 24 --x-to 722 --y-res 1024 --y-from 287 --y-to 674 --threads 2 --ttl 10
```

or

```
./loop.sh --url https://ya.ru --x-res 1024 --x-from 24 --x-to 722 --y-res 1024 --y-from 287 --y-to 674 --threads 2 --ttl 10
```

I think its possible to run it headless with xvfb, but this feature was not tested

```
xvfb-run ./loop.sh --url https://ya.ru --x-res 1024 --x-from 24 --x-to 722 --y-res 1024 --y-from 287 --y-to 674 --threads 2 --ttl 10
```
