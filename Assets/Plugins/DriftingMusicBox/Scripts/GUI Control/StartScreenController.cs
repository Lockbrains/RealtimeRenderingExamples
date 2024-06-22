using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class StartScreenController : MonoBehaviour
{
    public GameObject img_PressToStart;
    public GameObject img_title;
    public GameObject camera1;
    public GameObject playerGO;
    //public GameObject panel_settings;

    private bool keyboard_activated;
    

    // Start is called before the first frame update
    void Start()
    {
        img_PressToStart.SetActive(false);
        keyboard_activated = false;
        StartCoroutine(StartAnimation());
    }

    // Update is called once per frame
    void Update()
    {
        if(keyboard_activated && GameManager.S.status != GameManager.GameStatus.GameStart)
        {
            if(Input.anyKey)
            {
                StartCoroutine(EndAnimation());
            }
        }
    }

    IEnumerator StartAnimation()
    {
        yield return new WaitForSeconds(1.5f);
        img_PressToStart.SetActive(true);
        keyboard_activated = true;
    }

    IEnumerator EndAnimation()
    {
        img_title.SetActive(false);
        img_PressToStart.SetActive(false);
        camera1.GetComponent<Animator>().enabled = true;
        yield return new WaitForSeconds(2.0f);
        playerGO.SetActive(true);
        camera1.SetActive(false);
        GameManager.S.status = GameManager.GameStatus.GameStart;
    }


}
