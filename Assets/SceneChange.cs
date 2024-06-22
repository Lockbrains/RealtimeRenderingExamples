using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;


/* 
To use this script:
1- Add all the scenes you want to appear in the game:
Go to file > build scene... > add open scene

2- attach it to an object (even an empty one) whose position marks the "portal"

3- in the inspector drag the player object on "player" and type the scene. 
You can also adjust the distance that triggers the teleport

*/
public class SceneChange : MonoBehaviour
{
    public string sceneName = "";
    public GameObject player;
    public float distance = 2;

    // Start is called before the first frame update
    void Start()
    {
        if(player == null)
        {
            player = GameObject.Find("player");
        }
        
    }

    // Update is called once per frame
    void Update()
    {
        float d = Vector3.Distance(player.transform.position, transform.position);
        
        if(d<distance)
        {
            print("Changing scene to "+sceneName);
            SceneManager.LoadScene(sceneName);
        }
    }


}
